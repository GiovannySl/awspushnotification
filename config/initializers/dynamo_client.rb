module DynamodbClient
    module_function
    def create_user_table
        params = {
            table_name: 'users', # required
            key_schema: [ # required
                {
                    attribute_name: 'email', # required
                    key_type: 'HASH', # required, accepts HASH, RANGE
                }
            ],
            attribute_definitions: [ # required
                {
                    attribute_name: 'email', # required
                    attribute_type: 'S', # required, accepts S, N, B
                }
            ],
    
            provisioned_throughput: { # required
                                        read_capacity_units: 5, # required
                                        write_capacity_units: 5, # required
            }
        }
        begin
        result = DynamodbClient.client.create_table(params)
        render_message = {
            message: "Created table: users",
            status: 200
        }
      rescue Aws::DynamoDB::Errors::ServiceError => error
        render_message = {
            error: "Unable to create table: users; #{error.message}",
            status: 200
        }
      end
    end

    def create_logs_table
        params = {
            table_name: 'logs', # required
            key_schema: [ # required
            {
                attribute_name: 'email', # required User:1
                key_type: 'HASH', # required, accepts HASH, RANGE
            },
            {
                attribute_name: 'created_at', # timestamp
                key_type: 'RANGE'
            }
        ],
        attribute_definitions: [ # required
            {
                attribute_name: 'email', # required
                attribute_type: 'S', # required, accepts S, N, B
            },
            {
                attribute_name: 'created_at', # Timestamp
                attribute_type: 'S', # required, accepts S, N, B
            }
            ],
    
            provisioned_throughput: { # required
                                        read_capacity_units: 5, # required
                                        write_capacity_units: 5, # required
            }
        }
        begin
        result = DynamodbClient.client.create_table(params)
        render_message = {
            message: "Created table: logs",
            status: 200
        }
      rescue Aws::DynamoDB::Errors::ServiceError => error
        render_message = {
            error: "Unable to create table: #{error.message}",
            status: 200
        }
      end
    end

    def client
        client_config ={
            access_key_id: ENV['AWS_ACCESS_KEY_ID'], 
            secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'], 
            region: ENV['AWS_REGION']
        }        
        @client ||= Aws::DynamoDB::Client.new(client_config)
    end

    def get_all_users
        client
        response = @client.scan(table_name: 'users')
        items = response.items
        render_message = {
            users: items,
            status: 200
        }
    end

    def create_user(user_create_params)
        client
        # Search if user_id exists
        user = user_exists(user_create_params[:email])
        if user[:item]
            render_message = user[:render_message]
        else
            email = user_create_params[:email]
            cell_phone = user_create_params[:cell_phone]
            user_status = true
            item = {
                "email" => email,
                "cell_phone" => cell_phone,
                "push_status" => user_status
            } 
            params = {
                table_name: "users",
                item: item
            }
            begin
                result = @client.put_item(params)
                render_message = {
                    message: "Added item: email=#{email} - cellphone=#{cell_phone} - push_status=#{user_status}",
                    status: 200
                }
            rescue  Aws::DynamoDB::Errors::ServiceError => error
                render_message = {
                    error: "Unable to add item: #{error.message}",
                    status: 500
                }
            end
        end
    end
    
    def user_exists(email)
        unless @client
            client
        end
        begin
            response = @client.get_item({
                table_name: 'users',
                key: {
                "email" => email
                }
            })
            result = 
            {
                item: response.item,
                render_message:{
                    error: "This user alredy exists",
                    status: 200
                } 
            }
        rescue  Aws::DynamoDB::Errors::ServiceError => error
            result =
            {
                item: "error", 
                render_message:{
                    error: "Users table not found: #{error.message}",
                    status: 500
                } 
            }
        end
    end

    def active_user(email)
        unless @client
            client
        end
        @client.update_item({
            table_name: 'users',
            key: {
              'email' => email
            },
            update_expression: 'SET push_status = :push_status',
            expression_attribute_values: {
              ':push_status' => true
            }
          })
    end

    def soft_delete_user(email)
        unless @client
            client
        end
        @client.update_item({
            table_name: 'users',
            key: {
              'email' => email
            },
            update_expression: 'SET push_status = :push_status',
            expression_attribute_values: {
              ':push_status' => false
            }
          })
    end

    def update_cell_phone(email, cell_phone)
        unless @client
            client
        end
        @client.update_item({
            table_name: 'users',
            key: {
              'email' => email
            },
            update_expression: 'SET cell_phone = :cell_phone',
            expression_attribute_values: {
              ':cell_phone' => cell_phone
            }
          })
    end
end