module Spud

  class Updater

    attr_reader :context, :tmp_files, :stack_type, :stack_name
    attr_reader :current_template, :next_template, :current_description, :next_description

    def initialize(context, tmp_files, stack_type)
      @context = context
      @tmp_files = tmp_files
      @stack_type = stack_type

      @current_template = tmp_files.get(:current_template, stack_type)
      @next_template = tmp_files.get(:next_template, stack_type)
      @current_description = tmp_files.get(:current_description, stack_type)
      @next_description = tmp_files.get(:next_description, stack_type)

      @stack_name = next_description.data["Stacks"][0]["StackName"]
    end

    def run
      # FIXME some way of handling creation

      unless has_changes?
        UserInteraction.info_press_return "No changes for the #{stack_type} stack #{stack_name}"
        puts ""
        return
      end

      if Stubber.is_stub_description?(current_description.data)
        prompted_create
      else
        prompted_update
      end
    end

    def prompted_create
      puts "The #{stack_type} stack #{stack_name} is NEW"
      puts ""

      show_parameter_overrides

      unless UserInteraction.confirm_default_no(question: "Create the #{stack_type} stack #{stack_name}?")
        puts ""
        return
      end

      do_update
      puts ""
    end

    def prompted_update
      puts "Updates about to be applied to the #{stack_type} stack #{stack_name}:"
      puts ""
      show_diffs
      puts ""

      show_parameter_overrides

      unless UserInteraction.confirm_default_no(question: "Update the #{stack_type} stack #{stack_name}?")
        puts ""
        return
      end

      do_update
      puts ""
    end

    def has_changes?
      next_template.data != current_template.data or
      next_description.data != current_description.data
    end

    def show_diffs
      system "diff", "-u", current_description.path, next_description.path
      system "diff", "-u", current_template.path, next_template.path
    end

    def show_parameter_overrides
      d = next_description.data
      t = next_template.data
      show_param_overrides(t["Parameters"] || {}, params_to_hash(d))
    end

    def params_to_hash(description_data)
      (description_data["Stacks"][0]["Parameters"] || []).each_with_object({}) do |pair, h|
        h[ pair["ParameterKey"] ] = pair["ParameterValue"]
      end
    end

    def show_param_overrides(template_params, actual_params)
      if not template_params or template_params.empty? then
        puts "INFO: Template has no parameters"
        return
      end
      puts "INFO: Differences between parameter defaults and actual values:"
      has_diffs = false

      template_params.keys.sort.each do |key|
        default = template_params[key]["Default"]
        next if default.nil?
        actual = actual_params[key]
        next if actual == default

        puts "  #{key}"
        puts "    - #{default}"
        puts "    + #{actual}"
        has_diffs = true
      end

      if !has_diffs
        puts "  (none)"
      end

      puts ""
    end

    def do_update
      stacks = [stack_type].each_with_object({}) do |t, h|
        h[t] = {
          name: context.stacks[t].name,
          region: context.stacks[t].region,
          account_alias: context.stacks[t].account_alias,
          template: next_template.path,
          description: next_description.path,
        }
      end
      context.extensions.pusher.push_stacks(context, stacks)
    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
