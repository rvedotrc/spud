require 'json'
require 'aws-sdk'

module Spud

  module Ext

    class DefaultPuller

      def fetch_stacks(context, stacks)
        # FIXME could use concurrency here
        stack_types(stacks).each do |stack_type|
          pull_stack context, stacks[stack_type]
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

      def pull_stack(context, details)
        puts "Retrieving #{details[:type].inspect} stack #{details[:name].inspect}" \
          + " from #{details[:region]} in #{details[:account_alias] || 'the default account'}"

        stack = details[:name]

        cfn_client = get_client(details)

        if stack then
          (description_content, template_content) = fetch_stack_content(cfn_client, stack)
        else
          # FIXME: unclear that this code path is ever taken, since I think we
          # always have a stack name
          (description_content, template_content) = default_content
        end

        IO.write(details[:description], description_content)
        IO.write(details[:template], template_content)
      end

      def fetch_stack_content(cfn_client, stack_name)
        (description_content, template_content) = default_content
        begin
          # FIXME could use concurrency here
          d_resp = cfn_client.describe_stacks(stack_name: stack_name)
          t_resp = cfn_client.get_template(stack_name: stack_name)
          description_content = JSON.generate(d_resp.to_h)
          template_content = t_resp.template_body
        rescue Aws::CloudFormation::Errors::ValidationError => e
          # Eww!
          if e.to_s.match /Stack with id \S+ does not exist/
            (description_content, template_content) = default_content
          else
            raise
          end
        end
        [description_content, template_content]
      end

      def default_content
        ['{}', '{}']
      end

    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
