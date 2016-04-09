require 'json'
require 'shellwords'

module StackFetcher

  class StackComparer

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def compare
      d = context.stack_types.each_with_object({}) do |stack_type, h|
        h[stack_type] = {
          template: compare_template_files(
            tmp_files.current_template(stack_type),
            tmp_files.generated_template(stack_type),
          )
        }
      end

      ComparisonResult.new d
    end

    private

    def compare_template_files(file1, file2)
      # FIXME avoid repeatedly re-reading and re-parseing everything
      x = JSON.parse(IO.read file1)
      y = JSON.parse(IO.read file2)

      if x == y
        { result: :same }
      elsif strip_parameter_defaults(x) == strip_parameter_defaults(y)
        { result: :same_except_parameter_defaults }
      else
        { result: :different }.merge diff_stats(file1, file2)
      end
    end

    def strip_parameter_defaults(t)
      params = t["Parameters"]
      return t unless params

      no_defaults = params.entries.map do |k, v|
        copy = v.dup
        copy.delete "Default"
        [ k, copy ]
      end.to_h

      t.merge "Parameters" => no_defaults
    end

    def diff_stats(file1, file2)
      command = Shellwords.join([ "diff", "--", file1, file2 ])
      lines = `#{command}`.lines
      hunk_count = lines.select {|t| t.match /^\d+/ }.count
      lines_count = lines.count - hunk_count
      { hunks: hunk_count, lines: lines_count }
    end

  end

  class ComparisonResult

    def initialize(d)
      @d = d
    end

    def to_h
      @d
    end

    def print
      l = @d.keys.map(&:length).max
      l or return

      @d.entries.sort_by(&:first).each do |stack_type, r|
        r = r[:template]
        text = case r[:result]
               when :same
                 "same"
               when :same_except_parameter_defaults
                 "same, except for parameter defaults"
               when :different
                 "DIFFERENT (hunks: #{r[:hunks]}, lines: #{r[:lines]})"
               else
                 raise "Unknown comparison result: #{r.inspect}"
               end
        puts "  %-#{l}s : %s" % [ stack_type, text ]
      end
    end

  end

end
