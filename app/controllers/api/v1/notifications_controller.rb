class Api::V1::NotificationsController < Api::V1::BaseApiController
    swagger_controller :notifications, "Notification Management"
    

    swagger_api :send_push do
        summary "To send a push notification to an User"
        param :form, :token, :string, :required, "token"
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
                if result[:item]["push_status"]
                    cell_token = notification_params[:token]
                    sns = Aws::SNS::Client.new(region: ENV['AWS_REGION'])
                    unless result[:item]["token"] == notification_params[:token]
                        sns.delete_endpoint({
                            endpoint_arn: result[:item]["arn"], # required
                        })
                        cell_arn = sns.create_platform_endpoint(
                            platform_application_arn: "arn:aws:sns:us-west-2:606258166767:app/GCM/AwsPushNotification",
                            token: notification_params[:token],
                            attributes: {
                                "UserId" => "#{notification_params[:email]}"
                                }).endpoint_arn
                        DynamodbClient.change_token(notification_params[:email],notification_params[:token])
                        DynamodbClient.change_arn(notification_params[:email],cell_arn)
                    else
                        cell_arn = result[:item]["arn"]
                    end
                    local_time = Time.now.getlocal('-05:00').strftime("%m/%d/%Y a las %H:%M")
                    message_body = "El siguiente es un mensaje de texto de prueba solicitado el #{local_time} para #{result[:item]["email"]}."

                    message = {
                        default: { message: message_body }.to_json,
                        GCM: { notification: message_body }.to_json
                    # }
                    respp = sns.publish(
                        target_arn: cell_arn,
                        message: message.to_json,
                        message_structure: "json"
                    )
                    # format log params
                    longitude = notification_params[:longitude] || "nil"
                    latitude = notification_params[:latitude] || "nil"
                    log_params = {
                        email: notification_params[:email],
                        token: notification_params[:token],
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
        params.permit(:token, :email, :longitude, :latitude)
    end
end
