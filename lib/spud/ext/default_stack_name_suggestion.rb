

module Spud
  class DefaultStackNameSuggester

    #
    # type: stack type to suggest a name for.
    #
    def suggest_name(context, type)
      ScriptRunner.new(
        cmd: File.join(context.scripts_dir, "get-stack-name-suggestion"),
        args: [ type ] + context.argv,
      ).run!.output.chomp
    end
  end
end

# vi: ts=2 sts=2 sw=2 et :
