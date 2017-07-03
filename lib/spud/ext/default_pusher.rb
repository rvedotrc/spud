module Spud

  module Ext

    class DefaultPusher

      # args: array of args that spud was called with.
      # stacks {
      #     "<stack type>" => {
      #       :name => "<stack name>",
      #       :region => "<AWS region>", # might be nil
      #       :account_alias => "<AWS Account Alias>", # might be nil
      #       :template => "<File path from which the template should be read>"
      #       :description => "<File path from which the stack description should be read>"
      #     }, ...
      # }
      def push_stacks(context, stacks)
        spec = {
          args: context.argv,
          stacks: stacks
        }
        JsonSpecScriptRunner.new(
          cmd: File.join(context.scripts_dir, "push-stacks"),
          spec: spec,
        ).run!
      end

    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
