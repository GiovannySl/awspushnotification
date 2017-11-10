class UsersController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def create
        # Verify nil elelements
        unless user_params[:email] && user_params[:cell_phone]
            render_message = {
                error: "Params can't be blank",
                status: 422
            }
        else
            # format user params
            user_create_params = {
                email: user_params[:email],
                cell_phone: user_params[:cell_phone]
            }
            render_message = DynamodbClient.create_user(user_create_params)
        end
        render :json => render_message, :status => render_message[:status]
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

    def get_users
        render_message = DynamodbClient.get_all_users
        render :json => render_message, :status => render_message[:status]
    end

    def create_table
        render_message = DynamodbClient.create_user_table
        render :json => render_message, :status => render_message[:status]
    end

    def send_push
        result = DynamodbClient.user_exists(user_params[:email])
        if result[:item]
            case result[:render_message][:status]
            when 200
                if result[:item]["push_status"]
                    client = Aws::SNS::Client.new(region: ENV['AWS_REGION'])
                    client.publish({
                        phone_number: result[:item]["cell_phone"],
                        message: "PUSH notification to User= #{result[:item]["email"]}",
                    })
                    repsonse = "Push notification send"
                else
                    repsonse = "This user has push notification disabled"
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

    private
    def user_params
        # whitelist params
        params.permit(:cell_phone, :email)
    end
end
