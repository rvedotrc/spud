require 'json'

module Spud

  class StackFinder

    def initialize(context)
      @context = context
    end

    def get_names
      stacks = @context.stacks
      stacks.each do |stack|
        # FIXME saving the name should probably only happen right at the end,
        # when the stacks have been successfully pushed to AWS; and then, do
        # config load/amend/save in as small a window as possible.
        stack.name ||= prompted_name(stack.type)
        stack.region ||= prompted_region(stack.type)
        stack.account_alias ||= prompted_account_alias(stack.region)
      end
      stacks
    end

    private

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

      name
    end

    def get_suggestion(type)
      name = @context.extensions.stack_name_suggester.suggest_name(@context, type)
      
      if CloudformationLimits.valid_stack_name? name
        name
      else
        if name != ""
          $stderr.puts "Warning: stack name suggester gave an invalid stack name (#{name.inspect})"
        end
        nil
      end
    end

    def prompted_region(type)
      UserInteraction.get_mandatory_text(
        question: "Enter AWS region for the #{type.inspect} stack",
        prefill: ENV["AWS_REGION"],
      )
    end

    def prompted_account_alias(region)
      return nil if @context.extensions.account_alias_prompter.nil?
      @context.extensions.account_alias_prompter.prompt(region)
    end

  end

end

# vi: ts=2 sts=2 sw=2 et
