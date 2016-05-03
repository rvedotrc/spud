module Spud

  class Stubber

    def self.make_template
      {
        "AWSTemplateFormatVersion" => "2010-09-09",
        "Resources" => {},
      }
    end

    def self.make_description(stack_name)
      {
        "Stacks" => [
          {
            "StackName" => stack_name,
          }
        ],
      }
    end

  end

end
