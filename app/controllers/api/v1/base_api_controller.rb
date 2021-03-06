class Api::V1::BaseApiController < ApplicationController
    private
    # Swagger
  class << self
    Swagger::Docs::Generator::set_real_methods

    def inherited(subclass)
      super
      subclass.class_eval do
        setup_basic_api_documentation(subclass)
      end
    end
    private
    def setup_basic_api_documentation(subclass)
      [:create, :update_token, :active, :destroy, :me, :index,
      :get_users, :create_tables, :send_push].each do |api_action|
          swagger_api api_action do
          end
      end
    end
  end
end
  