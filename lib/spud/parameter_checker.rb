require 'json'

module Spud

  class ParameterChecker

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def check
      d = {}
      stop = false

      context.stack_types.each do |stack_type|
        description = tmp_files.get(:next_description, stack_type).data
        template = tmp_files.get(:next_template, stack_type).data
        r, this_stop = check_update(description, template)
        d[stack_type] = r
        stop ||= this_stop
      end

      ParameterCheckResult.new d, stop
    end

    private

    def check_update(description, template)
      r = {}
      stop = false

      c = changes_from_defaults(description, template)
      unless c.empty?
        r[:changes_from_defaults] = c
      end

      c = removed_parameters(description, template)
      unless c.empty?
        r[:removed_parameters] = c
        stop = true
      end

      c = added_parameters(description, template)
      unless c.empty?
        r[:added_parameters] = c
        stop = true
      end

      c = no_value_parameters(description, template)
      unless c.empty?
        r[:no_value_parameters] = c
        stop = true
      end

      [ r, stop ]
    end

    def changes_from_defaults(description, template)
      vals = description_parameter_values(description)
      defs = template_parameter_defaults(template)

      vals.each_with_object({}) do |(k,v), h|
        default = defs[k]
        if default && v != default
          h[k] = [ default, v ]
        end
      end
    end

    def removed_parameters(description, template)
      vals = description_parameter_values(description)
      defs = template_parameter_defaults(template)
      r = vals.keys - defs.keys

      description["Stacks"][0]["Parameters"].delete_if do |kv|
        r.include? kv["ParameterKey"]
      end
      
      r.sort
    end

    def added_parameters(description, template)
      vals = description_parameter_values(description)
      defs = template_parameter_defaults(template)
      r = defs.keys - vals.keys

      description["Stacks"][0]["Parameters"].concat(r.map do |k|
        { "ParameterKey" => k, "ParameterValue" => defs[k] }
      end.to_a)

      # FIXME better to use full stack normaliser
      description["Stacks"][0]["Parameters"].sort_by! {|param| param["ParameterKey"]}

      r.sort
    end

    def no_value_parameters(description, template)
      vals = description_parameter_values(description)
      defs = template_parameter_defaults(template)
      r = (defs.keys & vals.keys).select do |k|
        no_value?(vals[k]) and no_value?(defs[k])
      end
      r.sort
    end

    def no_value?(v)
      v.nil? or not v.match /\S/
    end

    def description_parameter_values(d)
      d["Stacks"][0]["Parameters"].each_with_object({}) do |p, h|
        h[ p["ParameterKey"] ] = p["ParameterValue"]
      end
    end

    def template_parameter_defaults(t)
      t["Parameters"].entries.each_with_object({}) do |(k,c), h|
        h[ k ] = c["Default"]
      end
    end

  end

  class ParameterCheckResult

    def initialize(d, stop)
      # overrides from defaults
      # missing parameter which has default, so added with default
      # missing parameter with no default, so added but value required
      # parameter present but no default and no value
      # gone parameter, so removed
      @d = d
      @stop = stop
    end

    def to_h
      @d
    end

    def stop?
      @stop
    end

    def render
      # puts "Rendering #{@d}"
      lines = [
        render_removed_parameters,
        render_added_parameters,
        render_changes_from_defaults,
        render_no_value_parameters,
      ].flatten
      t = lines.map {|l| l+"\n"}.join ""
      # puts "----", t, "----"
      t
    end

    private

    def render_changes_from_defaults
      lines = to_h.entries.sort_by(&:first).map do |stack_type, results|
        c = results[:changes_from_defaults] or next
        c.entries.sort_by(&:first).map do |k, (v1, v2)|
          "  #{stack_type} #{k} #{v1} #{v2}"
        end
      end.reject(&:nil?).flatten

      unless lines.empty?
        lines.unshift "Changes from defaults:"
        lines.push ""
      end

      lines
    end

    def render_removed_parameters
      lines = to_h.entries.sort_by(&:first).map do |stack_type, results|
        c = results[:removed_parameters] or next
        "  #{stack_type} #{c.sort.join " "}"
      end.reject(&:nil?)

      unless lines.empty?
        lines.unshift "Removed parameters:"
        lines.push ""
      end

      lines
    end

    def render_added_parameters
      lines = to_h.entries.sort_by(&:first).map do |stack_type, results|
        c = results[:added_parameters] or next
        "  #{stack_type} #{c.sort.join " "}"
      end.reject(&:nil?)

      unless lines.empty?
        lines.unshift "Added parameters:"
        lines.push ""
      end

      lines
    end

    def render_no_value_parameters
      lines = to_h.entries.sort_by(&:first).map do |stack_type, results|
        c = results[:no_value_parameters] or next
        "  #{stack_type} #{c.sort.join " "}"
      end.reject(&:nil?)

      unless lines.empty?
        lines.unshift "Parameters with no value and no default:"
        lines.push ""
      end

      lines
    end

  end

end
