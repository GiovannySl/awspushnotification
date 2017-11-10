class Api::V1::LogsController < Api::V1::BaseApiController
    swagger_controller :logs, "Logs Management"

    swagger_api :index do
        summary "To list all logs"
    end
    def index
        render_message = DynamodbClient.get_all_items("logs")
        render :json => render_message, :status => render_message[:status]
    end

    swagger_api :me do
        summary "To list all logs of an user"
        param :form, :email, :string, :required, "Email address"
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
