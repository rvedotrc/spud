require 'hash-sorter'
require 'json'

# Only make NON-FUNCTIONAL changes to the json
# e.g. whitespace, exchanging null with [] or {}, etc.

# For easier comparisons, e.g. by diff

module StackFetcher

  class StackNormaliser

    def initialize(optimise_policies = false)
      @optimise_policies = optimise_policies
    end

    def normalise_stack(d)
      # Deep clone
      d = JSON.parse(JSON.generate d)

      if d["Stacks"]
        normalise_description d
      elsif d["AWSTemplateFormatVersion"]
        normalise_template d
      elsif d["TemplateBody"]
        d["TemplateBody"] = normalise_template d["TemplateBody"]
        d
      else
        raise "Unrecognised stack json"
      end
    end

    private

    def normalise_description(d)
      d["Stacks"].each do |stack|
        (stack["Parameters"] ||= []).sort_by! { |v| v["ParameterKey"] }
        (stack["Tags"]       ||= []).sort_by! { |v| v["Key"] }
        (stack["Outputs"]    ||= []).sort_by! { |v| v["OutputKey"] }
        (stack["Capabilities"] ||= []).sort!
        (stack["NotificationARNs"] ||= []).sort!
      end
      d
    end

    def normalise_template(d)
      (d["Resources"] ||= {}).values.each do |r|
        r.delete "Properties" if r.has_key? "Properties" and r["Properties"].empty?
        r["Properties"] = normalise_resource_properties(r["Type"], r["Properties"]) if r.has_key? "Properties"
      end

      %w[ Parameters Outputs Mappings Conditions Resources Properties ].each do |k|
        d.delete k if d.has_key? k and d[k].empty?
      end

      d
    end

    def normalise_resource_properties(type, properties)
      case type
      when "AWS::IAM::Policy"
        normalise_iam_policy_properties(properties)
      when "AWS::IAM::Role"
        normalise_iam_role_properties(properties)
      when "AWS::CloudWatch::Alarm"
        normalise_alarm_threshold(properties)
      else
        properties
      end
    end

    def normalise_iam_policy_properties(properties)
      if @optimise_policies
        optimise_policy properties["PolicyDocument"]
      end

      normalise_policy_document properties["PolicyDocument"]

      properties
    end

    def normalise_iam_role_properties(properties)
      normalise_policy_document properties["AssumeRolePolicyDocument"]
      properties
    end

    def normalise_alarm_threshold(properties)
      # Avoid diffs were 3000000000.0 != 3000000000 as CF applies same normalisation server-side anyway.
      t = properties['Threshold']

      if t.kind_of? Numeric
        ti = t.to_i
        properties['Threshold'] = ti if ti == t
      end

      properties
    end

    def normalise_policy_document(d, make_array = false)
      if d["Statement"].kind_of? Hash
        d["Statement"] = [ d["Statement"] ]
      end

      d["Statement"].each do |statement|
        # TODO also NotAction, NotResource
        ["Action", "Resource"].each do |key|
          if statement[key].kind_of? Array
            statement[key].sort_by! { |x| JSON.generate([HashSorter.new.sort_hash(x)]) }
            statement[key].uniq!
            if !make_array and statement[key].count == 1
              statement[key] = statement[key].first
            end
          elsif statement[key] and make_array
            statement[key] = [ statement[key] ]
          end
        end
      end
      d["Statement"].sort_by! { |x| JSON.generate([HashSorter.new.sort_hash(x)]) }
    end

    def optimise_policy(d)
      normalise_policy_document d, true

      # TODO also NotAction, NotResource
      ["Resource", "Action"].each do |by|
        by_non_foo = {}

        d["Statement"].each do |statement|
          resource = statement.delete by
          resource or raise "Statement was missing #{by.inspect} - can't optimise policy: #{statement.inspect}"
          by_non_foo[statement] ||= []
          by_non_foo[statement].concat resource
        end

        d["Statement"] = by_non_foo.entries.map do |entry|
          most, resources = entry
          most.merge by => resources
        end
      end
    end

  end

end
