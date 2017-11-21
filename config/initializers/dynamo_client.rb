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

    def get_user_logs(email)
        client
        response = @client.scan({
            scan_filter: {
                "email" => {
                    attribute_value_list: [email], # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
                    comparison_operator: "EQ", # required, accepts EQ, NE, IN, LE, LT, GE, GT, BETWEEN, NOT_NULL, NULL, CONTAINS, NOT_CONTAINS, BEGINS_WITH
                },
            }, 
            table_name: "logs", 
        })
        items = response.items
        items = (items.sort_by { |hsh| hsh["created_at"] }.reverse!)        
        render_message = {
            logs: items,
            status: 200
        }
    end

    def get_all_items(table)
        client
        response = @client.scan(table_name: table)
        items = response.items
        items = (items.sort_by { |hsh| hsh["created_at"] }.reverse!)
        render_message = {
            items: items,
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
            token = user_create_params[:token]
            user_status = true
            longitude = user_create_params[:longitude]
            latitude = user_create_params[:latitude]
            created_at = Time.now.strftime("%m/%d/%Y %H:%M") 
            item = {
                "email" => email,
                "token" => token,
                "push_status" => user_status,
                "longitude" => longitude,
                "latitude" => latitude,
                "created_at" => created_at
            } 
            params = {
                table_name: "users",
                item: item
            }
            begin
                result = @client.put_item(params)
                render_message = {
                    message: "Added item: User = #{email}}",
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
    
    def save_log(log_params)
        client
        # Search if user_id exists
        email = log_params[:email]
        token = log_params[:token]
        longitude = log_params[:longitude]
        latitude = log_params[:latitude]
        message = log_params[:message]
        created_at = Time.now.strftime("%m/%d/%Y %H:%M") 
        item = {
            "email" => email,
            "token" => token,
            "message" => message,
            "longitude" => longitude,
            "latitude" => latitude,
            "created_at" => created_at
        } 
        params = {
            table_name: "logs",
            item: item
        }
        begin
            result = @client.put_item(params)
            render_message = "Added item: log"
        rescue  Aws::DynamoDB::Errors::ServiceError => error
            render_message = "Unable to add item: #{error.message}"
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

    def update_token(email, token)
        unless @client
            client
        end
        @client.update_item({
            table_name: 'users',
            key: {
              'email' => email
            },
            update_expression: 'SET token = :token',
            expression_attribute_values: {
              ':token' => token
            }
          })
    end
end