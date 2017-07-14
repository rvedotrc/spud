require 'json'
require 'aws-sdk'
require 'cfn-events'

module Spud

  module Ext

    # In the default implementation, account_alias is ignored.
    class DefaultPusher

      def push_stacks(context, stacks)
        stack_types(stacks).each do |stack_type|
          push_stack context, stacks[stack_type]
        end
      end

      # Stacks are processed in this order
      def stack_types(stacks)
        stacks.keys.sort
      end

      # Get a CloudFormation client for pushing a specific stack
      def get_client(details)
        Aws::CloudFormation::Client.new(get_config(details))
      end

      # Get a CloudFormation client config for pushing a specific stack
      def get_config(details)
        config = {}
        config[:http_proxy] = get_proxy
        config[:region] = details[:region] if details[:region]
        config
      end

      def get_proxy
        e = ENV['https_proxy']
        e = "https://#{e}" if e && !e.empty? && !e.start_with?('http')
        return e
      end

      private

      def push_stack(context, details)
        # :name, :region, :account_alias, :template, :description
        description = JSON.parse(IO.read details[:description])
        description = description["Stacks"][0]

        # Reduce whitespace
        template = JSON.generate(JSON.parse(IO.read details[:template]))

        start = Time.now

        method = stack_name_or_id = region = nil
        if description["StackId"]
          method = :update_stack
          stack_name_or_id = description["StackId"]
          region = stack_name_or_id.split(/:/)[3] # arn:aws:cloudformation:region:acount:...
        else
          method = :create_stack
          stack_name_or_id = details[:name]
          region = details[:region]
        end
        puts "Pushing stack #{stack_name_or_id} using #{method} via region #{region.inspect}"

        cfn_client = get_client(details)

        r = cfn_client.send(
          method,
          stack_name: stack_name_or_id,
          template_body: template,
          parameters: description["Parameters"].map do |param|
            {
              parameter_key: param["ParameterKey"],
              parameter_value: param["ParameterValue"],
            }
          end,
          capabilities: description["Capabilities"],
          notification_arns: description["NotificationARNs"],
          tags: description["Tags"].map do |tag|
            {
              key: tag["Key"],
              value: tag["Value"],
            }
          end,
        )
        puts ""

        watch_stack_events r.stack_id, cfn_client, start - 60
      end

      def watch_stack_events(stack_id, cfn_client, since)
        config = CfnEvents::Config.new
        config.cfn_client = cfn_client
        config.stack_name_or_id = stack_id
        config.wait = true
        config.since = since

        rc = CfnEvents::Runner.new(config).run
        # FIXME do we care about non-zero return code?
      end

    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
