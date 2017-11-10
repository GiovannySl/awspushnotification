class Swagger::Docs::Config
  def self.transform_path(path, api_version)
    # Make a distinction between the APIs and API documentation paths.
    "docs/#{path}"
  end
end

Swagger::Docs::Config.register_apis({
    "1.0" => {
      # the extension used for the API
      #:api_extension_type => :json,
      # the output location where your .json files are written to
      :api_file_path => "public/docs/",
      # the URL base path to your API
      :base_path => "http://localhost:3000/",
      #:base_path => "http://50.112.74.36:3000/",
      # if you want to delete all .json files at each generation
      :clean_directory => true,
      # Ability to setup base controller for each api version. Api::V1::SomeController for example.
      #:parent_controller => Api::V1::SomeController,
      # add custom attributes to api-docs
      :attributes => {
        :info => {
          "title" => "PUSH Notifications",
          "description" => "API for PUSH Notifications.",
          "contact" => "gsalazar@tie.in.com",
          "license" => "Apache 2.0",
          "licenseUrl" => "http://www.apache.org/licenses/LICENSE-2.0.html"
        }
      }
    }
  })
Swagger::Docs::Config.base_api_controller = ActionController::API
  