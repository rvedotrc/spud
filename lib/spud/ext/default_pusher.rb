require 'json'
require 'aws-sdk'
require 'cfn-events'

module Spud

  module Ext

    # In the default implementation, account_alias is ignored.
    class DefaultPusher

      def initialize
        @change_set_descriptions = {}
      end

      def prepare(context, stacks)
        stack_types(stacks).each do |stack_type|
          prepare_stack context, stack_type, stacks[stack_type]
        end
      end

      def push_stacks(context, stacks)
        stack_types(stacks).each do |stack_type|
          push_stack context, stack_type, stacks[stack_type]
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

      def prepare_stack(context, stack_type, details)
        cfn_client = get_client(details)

        change_set_id = create_change_set context, details, cfn_client
        change_set_description = wait_for_change_set_to_be_available change_set_id, cfn_client
        display_change_set change_set_description

        @change_set_descriptions[stack_type] = change_set_description
      end

      def push_stack(context, stack_type, details)
        start = Time.now

        cfn_client = get_client(details)
        change_set_description = @change_set_descriptions[stack_type]
        p change_set_description

        r = cfn_client.execute_change_set(change_set_name: change_set_description.change_set_id)
        p r
        puts ""

        watch_stack_events change_set_description.stack_id, cfn_client, start - 60
      end

      def create_change_set(context, details, cfn_client)
        change_set_name = "spud-changeset-#{Time.now.to_i}"

        # :name, :region, :account_alias, :template, :description
        description = JSON.parse(IO.read details[:description])
        description = description["Stacks"][0]

        # Reduce whitespace
        template = JSON.generate(JSON.parse(IO.read details[:template]))

        change_set_type = stack_name_or_id = nil
        if description["StackId"]
          change_set_type = "UPDATE"
          stack_name_or_id = description["StackId"]
        else
          change_set_type = "CREATE"
          stack_name_or_id = details[:name]
        end
        puts "Creating #{change_set_type} change set for stack #{stack_name_or_id}"

        r = cfn_client.create_change_set(
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
          change_set_name: change_set_name,
          change_set_type: change_set_type,
        )

        r.id
      end

      def wait_for_change_set_to_be_available(change_set_id, cfn_client)
        r = nil

        puts "Waiting for change set to be available for execution ..."
        loop do
          r = cfn_client.describe_change_set(change_set_name: change_set_id)
          p [ r.status, r.execution_status, r.status_reason ]

          # Typical:
          # ["CREATE_PENDING", "UNAVAILABLE", nil]
          # ["CREATE_IN_PROGRESS", "UNAVAILABLE", nil]
          # ["CREATE_COMPLETE", "AVAILABLE", nil]

          # No changes:
          # ["FAILED", "UNAVAILABLE", "The submitted information didn't contain changes. Submit different information to create a change set."]

          if r.execution_status == "AVAILABLE"
            puts ""
            return r
          end

          if r.status == "FAILED"
            puts "Change set failed: #{r.status_reason}"
            collect_change_set_for_analysis r
            exit 1
          end

          sleep 1
        end
      end

      def display_change_set(change_set)
        puts "Change set is now available for execution:"
        data = HashSorter.new.sort_hash(change_set.to_h)
        puts JSON.pretty_generate(data)
        collect_change_set_for_analysis change_set
        puts ""
      end
      protected :display_change_set

      def collect_change_set_for_analysis(change_set)
        data = HashSorter.new.sort_hash(change_set.to_h)
        content = JSON.pretty_generate(data) + "\n"

        filename = "/tmp/spud-changeset-#{change_set.stack_name}-#{Time.now.utc.to_i}.json"
        tmp = filename + ".tmp"
        IO.write(tmp, content)
        File.rename tmp, filename
        puts "(changeset saved for analysis purposes to #{filename})"
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
