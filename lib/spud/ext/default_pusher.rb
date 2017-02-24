module Spud
  class DefaultPusher

    #
    # stacks {
    #     "<stack type>" => {
    #       :name => "<stack name>",
    #       :region => "<AWS region alias>",
    #       :account_alias => "<AWS Account Alias>",
    #       :template => "<File path from which the template should be read>"
    #       :description => "<File path from which the stack description should be read>"
    #     }, ...
    # }
    #
    #
    def push_stacks(context, stacks)
      spec = {
        args: context.args,
        stacks: stacks
      }
      JsonSpecScriptRunner.new(
        cmd: File.join(context.scripts_dir, "push-stacks"),
        spec: spec,
      ).run!
    end
  end
end

# vi: ts=2 sts=2 sw=2 et :

