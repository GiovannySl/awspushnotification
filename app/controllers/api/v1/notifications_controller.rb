class Api::V1::NotificationsController < Api::V1::BaseApiController
    swagger_controller :notifications, "Notification Management"
    

    swagger_api :send_push do
        summary "To send a push notification to an User"
        param :form, :cell_phone, :string, :required, "cell_phone e.g. 753005554444"
        param :form, :email, :string, :required, "Email address"
        param :form, :longitude, :string, :optional, "Longitude"
        param :form, :latitude, :string, :optional, "Latitude"
        response 200, "User not found"
        response 200, "{push_notifiation: 'Push notification send', logs: 'Added item: log'}"
        response 200, "{push_notifiation: 'Push notification send', logs: 'Unable to add item: [Dynamo error message]'}"
        response 500, "Users table not found: [Dynamo error message]"
        response 200, "This user has push notification disabled"
        response 500, "Internal Error"
    end
    def send_push
        result = DynamodbClient.user_exists(notification_params[:email])
        if result[:item]
            case result[:render_message][:status]
            when 200
                if result[:item]["push_status"] && notification_params[:cell_phone] == result[:item]["cell_phone"]
                    client = Aws::SNS::Client.new(region: ENV['AWS_REGION'])
                    local_time = Time.now.getlocal('-05:00').strftime("%m/%d/%Y a las %H:%M")
                    message = "El siguiente es un mensaje de texto de prueba solicitado el #{local_time} para #{result[:item]["email"]} al número +#{result[:item]["cell_phone"]}."
                    client.publish({
                        phone_number: result[:item]["cell_phone"],
                        message: message,
                    })
                    # format log params
                    longitude = notification_params[:longitude] || "nil"
                    latitude = notification_params[:latitude] || "nil"
                    log_params = {
                        email: notification_params[:email],
                        cell_phone: notification_params[:cell_phone],
                        longitude: longitude,
                        latitude: latitude,
                        message: message
                    }
                    log_message = DynamodbClient.save_log(log_params)
                    repsonse = {push_notifiation: "Push notification send",
                                logs: log_message}
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

    swagger_api :verify_number do
        summary "To send the last 4 digits of the cell phone"
        param :form, :email, :string, :required, "Email address"
        response 200, "e.g. = '5555'"
        response 200, "User not found"
        response 500, "Users table not found: [Dynamo error message]"
    end
    def verify_number
        result = DynamodbClient.user_exists(notification_params[:email])
        if result[:item]
            case result[:render_message][:status]
            when 200
                repsonse = result[:item]["cell_phone"].last(4)
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

    swagger_api :create_tables do
        summary "To create the users table on Dynamodb"
    end
    def create_tables
        render_message_1 = DynamodbClient.create_user_table
        render_message_2 = DynamodbClient.create_logs_table
        render :json => {
            user_table: render_message_1,
            logs_table: render_message_2},
            :status => render_message_1[:status]
    end

    private
    def notification_params
        # whitelist params
        params.permit(:cell_phone, :email, :longitude, :latitude)
    end
end
