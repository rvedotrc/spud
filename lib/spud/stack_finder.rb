require 'json'

module Spud

  class StackFinder

    def initialize(context)
      @context = context
    end

    def get_names
      @context.stack_types.each_with_object({}) do |type, h|
        h[type] = get_name(type)
      end
    end

    private

    def get_name(type)
      saved_name(type) || prompted_name(type)
    end

    def saved_name(type)
      @context.stack_names[type]
    end

    def save_name(type, name)
      @context.stack_names = {type => name}
    end

    def prompted_name(type)
      suggestion = get_suggestion(type)
      puts "suggestion is #{suggestion}"

      name = nil
      loop do
        name = UserInteraction.get_mandatory_text(
          question: "Enter name for the #{type.inspect} stack",
          prefill: suggestion,
        )
        break if CloudformationLimits.valid_stack_name? name
        puts "That's not a valid stack name, please try again"
      end

      # FIXME save_name (and then save the config) should probably only happen
      # right at the end, when the stacks have been successfully pushed to
      # AWS; and then, do config load/amend/save in as small a window as
      # possible.
      save_name(type, name)

      name
    end

    def get_suggestion(type)
      name = @context.extensions.stack_name_suggester.suggest_name(@context, type)

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

# vi: ts=2 sts=2 sw=2 et
