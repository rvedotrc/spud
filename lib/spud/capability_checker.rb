require 'json'

module Spud

  class CapabilityChecker

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def check?
      stop = false

      context.stack_types.each do |stack_type|
        if !capabilities_ok?(stack_type)
          stop = true
        end
      end

      puts "" if stop

      !stop
    end

    def capabilities_ok?(stack_type)
      template = tmp_files.get(:next_template, stack_type).data
      description = tmp_files.get(:next_description, stack_type).data

      if needs_iam?(template) and !has_capability?(description, "CAPABILITY_IAM")
        puts "The #{stack_type} stack requires CAPABILITY_IAM - you must add this capability to continue."
        unless UserInteraction.confirm_default_yes(question: "Add CAPABILITY_IAM?")
          return
        end
        add_capability(description, "CAPABILITY_IAM")
      end

      true
    end

    private

    def needs_iam?(template)
      template["Resources"].values.any? do |res|
        res["Type"].match /^AWS::IAM::/
      end
    end

    def has_capability?(description, capability)
      description["Stacks"][0]["Capabilities"].include? capability
    end

    def add_capability(description, capability)
      description["Stacks"][0]["Capabilities"] << capability
    end

  end

end
