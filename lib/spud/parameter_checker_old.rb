require 'json'

module Spud

  class ParameterCheckerOld

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def check?
      stop = false

      context.stack_types.each do |stack_type|
        if !parameters_ok?(stack_type)
          stop = true
        end
      end

      puts "" if stop

      !stop
    end

    def parameters_ok?(stack_type)
      template = tmp_files.get(:next_template, stack_type).data
      description = tmp_files.get(:next_description, stack_type).data

      want_keys = (template["Parameters"] || {}).keys.sort
      got_keys = (description["Stacks"][0]["Parameters"] || []).map {|p| p["ParameterKey"]}.sort

      description_changed = false

      keys_added = want_keys - got_keys
      if !keys_added.empty?
        puts ""
        puts "The following parameters are defined the #{stack_type} stack template, but don't have values in the description:"
        puts "  #{keys_added.join " "}"
        puts "These parameters will be added to the description with their default values."

        p = (description["Stacks"][0]["Parameters"] ||= [])
        description["Stacks"][0]["Parameters"] = p

        keys_added.each do |k|
          p << {
            "ParameterKey" => k,
            "ParameterValue" => template["Parameters"][k]["Default"], # might be nil
          }
        end

        description_changed = true
      end

      keys_removed = got_keys - want_keys
      if !keys_removed.empty?
        puts ""
        puts "The following parameters have values in the #{stack_type} stack description, but aren't in the template:"
        puts "  #{keys_removed.join " "}"
        puts "These parameters will be removed from the description file."

        description["Stacks"][0]["Parameters"].delete_if {|p|
          keys_removed.include? p["ParameterKey"]
        }
        description_changed = true
      end

      if description_changed
        puts ""
        puts "Automatic changes have been made.  Please check/edit as appropriate, then re-run spud."
      end

      # TODO check CloudFormation docs/behaviour: is empty string a valid value for a parameter?
      missing_values = (description["Stacks"][0]["Parameters"] || []) \
        .select {|p| !p["ParameterValue"] } \
        .map {|p| p["ParameterKey"] }

      if !missing_values.empty?
        puts ""
        puts "The following parameters in the #{stack_type} stack need a value:"
        puts "  #{missing_values.sort.join " "}"
      end

      !description_changed && missing_values.empty?
    end

  end

end
