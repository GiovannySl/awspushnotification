 class Api::V1::UsersController < Api::V1::BaseApiController
    swagger_controller :users, "User Management"
    
    swagger_api :create do
        summary "Creates a new User"
        param :form, :cell_phone, :string, :required, "Cell_phone"
        param :form, :email, :string, :required, "Email address"
        param :form, :longitude, :string, :required, "Longitude"
        param :form, :latitude, :string, :required, "Latitude"        
    end
    def create
        # Verify nil elelements
        unless user_params[:email] && user_params[:cell_phone]
            render_message = {
                error: "Email and phone can not be blank",
                status: 422
            }
        else
            # format user params
            longitude = user_params[:longitude] || "nil"
            latitude = user_params[:latitude] || "nil"
            user_create_params = {
                email: user_params[:email],
                cell_phone: user_params[:cell_phone],
                longitude: longitude,
                latitude: latitude
            }
            render_message = DynamodbClient.create_user(user_create_params)
        end
        render :json => render_message, :status => render_message[:status]
    end

    swagger_api :update_cell_phone do
        summary "Update the cellphone number of an User"
        param :form, :cell_phone, :string, :required, "cell_phone"
        param :form, :email, :string, :required, "Email address"
    end
    def update_cell_phone
        result = DynamodbClient.user_exists(user_params[:email])
        if result[:item]
            case result[:render_message][:status]
            when 200
                DynamodbClient.update_cell_phone(user_params[:email], user_params[:cell_phone])
                render_message = 
                {
                    message: "cellphone number updated",
                    status: 200
                }
            else
                render_message = result[:render_message]
            end
        else
            render_message = 
            {
                message: "User not found",
                status: 200
            }
        end
        render :json => render_message, :status => render_message[:status]
    end

    swagger_api :active do
        summary "To active push notification from an User"
        param :form, :email, :string, :required, "Email address"
    end
    def active
        result = DynamodbClient.user_exists(user_params[:email])
        if result[:item]
            case result[:render_message][:status]
            when 200
                if result[:item]["push_status"]
                    repsonse = "This user is already active"
                else
                    DynamodbClient.active_user(user_params[:email])
                    repsonse = "This user is now active"
                end
                render_message = 
                {
                    message: repsonse,
                    status: 200
                }
            else
                render_message = result[:render_message]
            end
        else
            render_message = 
            {
                message: "User not found",
                status: 200
            }
        end
        render :json => render_message, :status => render_message[:status]
    end

    swagger_api :destroy do
        summary "To disable push notification from an User"
        param :form, :email, :string, :required, "Email address"
    end
    def destroy
        result = DynamodbClient.user_exists(user_params[:email])
        if result[:item]
            case result[:render_message][:status]
            when 200
                unless result[:item]["push_status"]
                    repsonse = "This user is already disabled"
                else
                    DynamodbClient.soft_delete_user(user_params[:email])
                    repsonse = "This user is now disabled"
                end
                render_message = 
                {
                    message: repsonse,
                    status: 200
                }
            else
                render_message = result[:render_message]
            end
        else
            render_message = 
            {
                message: "User not found",
                status: 200
            }
        end
        render :json => render_message, :status => render_message[:status]
    end

    swagger_api :get_users do
        summary "To get all Users"
    end
    def get_users
        render_message = DynamodbClient.get_all_items("users")
        render :json => render_message, :status => render_message[:status]
    end

    private
    def user_params
        # whitelist params
        params.permit(:cell_phone, :email, :longitude, :latitude)
    end
end
