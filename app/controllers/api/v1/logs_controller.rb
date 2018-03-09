class Api::V1::LogsController < Api::V1::BaseApiController
    swagger_controller :logs, "Logs Management"

    swagger_api :index do
        summary "To list all logs"
        response 200, "items: [{Log_1},..,{Log_n}] ; order by created_at"        
    end
    def index
        render_message = DynamodbClient.get_all_items("logs")
        render :json => render_message, :status => render_message[:status]
    end

    swagger_api :me do
        summary "To list all logs of an user"
        param :form, :email, :string, :required, "Email address"
        response 200, "logs: [{User_log_1},..,{User_log_n}] ; order by created_at"        
    end
    def me
        render_message = DynamodbClient.get_user_logs(logs_params[:email])
        render :json => render_message, :status => render_message[:status]
    end

    private
    def logs_params
        # whitelist params
        params.permit(:email)
    end
end
