require 'json'

module Spud

  class StackFinder

    attr_reader :context

    def initialize(context)
      @context = context
    end

    def get_names
      context.stack_types.each_with_object({}) do |type, h|
        h[type] = get_name(type)
      end
    end

    private

    def get_name(type)
      saved_name(type) || prompted_name(type)
    end

    def saved_name(type)
      context.config[type]
    end

    def save_name(type, name)
      context.config[type] = name
    end

    def prompted_name(type)
      suggestion = get_suggestion(type)

      name = nil
      loop do
        name = UserInteraction.get_mandatory_text(
          question: "Enter name for the #{type.inspect} stack",
          prefill: suggestion,
        )
        break if CloudformationLimits.valid_stack_name? name
        puts "That's not a valid stack name, please try again"
      end

      save_name(type, name)
      name
    end

    def get_suggestion(type)
      name = ScriptRunner.new(
        cmd: File.join(context.scripts_dir, "get-stack-name-suggestion"),
        args: [ type ] + context.argv,
      ).run!.output.chomp

      if CloudformationLimits.valid_stack_name? name
        name
      else
        if name != ""
          $stderr.puts "Warning: get-stack-name-suggestion gave an invalid stack name (#{name.inspect})"
        end
        nil
      end
    end

  end

end
