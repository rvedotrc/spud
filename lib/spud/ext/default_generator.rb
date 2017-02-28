

module Spud
  class DefaultGenerator
      
    #
    # args: array of args that spud was called with.
    # stacks {
    #     "<stack type>" => {
    #       :name => "<stack name>",
    #       :region => "<AWS region alias>",
    #       :account_alias => "<AWS Account Alias>",
    #       :template => "<File path into which the stack template should be written>"
    #       :description => "<File path into which the stack description should be written>"
    #     }, ...
    # }
    #
    #
    def generate(context, stacks)
      spec = {
        args: context.args,
        stacks: stacks
      }
      JsonSpecScriptRunner.new(
        cmd: File.join(context.scripts_dir, "generate-stacks"),
        spec: spec,
      ).run!
    end
  end
end

# vi: ts=2 sts=2 sw=2 et :
