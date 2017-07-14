module Spud

  module Ext

    class ScriptingStackNameSuggester

      # type: stack type to suggest a name for.
      # args: array of args that spud was called with, which we then prefix
      # with the stack type
      def suggest_name(context, type)
        ScriptRunner.new(
          cmd: File.join(context.scripts_dir, "get-stack-name-suggestion"),
          args: [ type ] + context.argv,
        ).run!.output.chomp
      end

    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
