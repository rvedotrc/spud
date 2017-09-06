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

      if needs_named_iam?(template) and !has_capability?(description, "CAPABILITY_NAMED_IAM")
        return unless prompted_add_capability(stack_type, description, 'CAPABILITY_NAMED_IAM')
      elsif needs_iam?(template) and !has_capability?(description, "CAPABILITY_IAM") and !has_capability?(description, "CAPABILITY_NAMED_IAM")
        return unless prompted_add_capability(stack_type, description, 'CAPABILITY_IAM')
      end

      true
    end

    def prompted_add_capability(stack_type, description, required_capability)
      puts "The #{stack_type} stack requires #{required_capability} - you must add this capability to continue."

      unless UserInteraction.confirm_default_yes(question: "Add #{required_capability}?")
        return false
      end

      add_capability(description, required_capability)

      true
    end

    private

    def needs_iam?(template)
      # (Currently) the list of resource types is actually:
      #  AWS::IAM::AccessKey, AWS::IAM::Group, AWS::IAM::InstanceProfile,
      #  AWS::IAM::Policy, AWS::IAM::Role, AWS::IAM::User, and
      #  AWS::IAM::UserToGroupAddition
      # See http://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_CreateStack.html
      template["Resources"].values.any? do |res|
        res["Type"].match /^AWS::IAM::/
      end
    end

    def needs_named_iam?(template)
      template["Resources"].values.any? do |res|
        case res["Type"]
        when "AWS::IAM::Group"
          res["Properties"] and res["Properties"]["GroupName"]
        when "AWS::IAM::Policy"
          res["Properties"] and res["Properties"]["PolicyName"]
        when "AWS::IAM::Role"
          res["Properties"] and res["Properties"]["RoleName"]
        when "AWS::IAM::User"
          res["Properties"] and res["Properties"]["UserName"]
        end
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
