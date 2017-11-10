Rails.application.routes.draw do
  root 'users#get_users'
  scope '/', defaults: { format: :json } do

    get '/create_table', to:'users#create_table'
    get '/', to: 'users#get_users'
    post '/create_user', to: 'users#create'
    post '/active', to: 'users#active'
    post '/destroy', to: 'users#destroy'
    post '/send_push', to: 'users#send_push'
    post '/update_cell_phone', to: 'users#update_cell_phone'

  end
end
