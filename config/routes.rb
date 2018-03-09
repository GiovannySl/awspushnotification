Rails.application.routes.draw do
  root 'users#get_users'
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        get '/', to: 'users#get_users'
        post '/create_user', to: 'users#create'
        post '/active', to: 'users#active'
        post '/destroy', to: 'users#destroy'
        post '/update_cell_phone', to: 'users#update_cell_phone'
        
        get '/create_tables', to:'notifications#create_tables'
        post '/send_push', to: 'notifications#send_push'
        post '/verify_number', to: 'notifications#verify_number'

        get '/logs', to:'logs#index'
        post '/user_logs', to:'logs#me'
      end
    end
end
