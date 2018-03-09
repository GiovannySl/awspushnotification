module SnsClient
    module_function

    def get_all_topics
        all_topics = []
        sns = Aws::SNS::Resource.new(region: ENV['AWS_REGION'])
        sns.topics.each do |topic|
            all_topics.push({topic: topic, topic_arn:topic.arn})
        end
        all_topics
    end

    def create_topic
        sns = Aws::SNS::Resource.new(region: ENV['AWS_REGION'])
        topic = sns.create_topic(name: 'PushNotifications')
        result = topic.arn
    end

    def get_all_subscriptions
        all_subscriptions = []
        sns = Aws::SNS::Resource.new(region: ENV['AWS_REGION'])
        sns.topics.each do |topic|
            topic = sns.topic(topic.arn)
            topic.subscriptions.each do |subs|
                all_subscriptions.push({
                    subscription: subs,
                    subscription_endpoint: subs.attributes['Endpoint']
                }) 
            end
        end
        all_subscriptions
    end

    def create_subscription
        sns = Aws::SNS::Resource.new(region: ENV['AWS_REGION'])
        topic = sns.topic(ENV['TOPIC_ARN'])
        sub = topic.subscribe({
          protocol: 'sms',
          endpoint: '75-3004211449'
        })
        puts sub.arn
    end
    
    def send_push_notification
        client = Aws::SNS::Client.new(region: ENV['AWS_REGION'])
        client.publish({
            phone_number: "573004211449",
            message: "Push",
        })
    end
end