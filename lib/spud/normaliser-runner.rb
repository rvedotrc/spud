require 'json'

module Spud

  class NormaliserRunner

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def normalise_all
      files.each do |f|
        normalise_file f
      end
    end

    private

    def files
      context.stack_types.map do |t|
        [
          tmp_files.current_template(t),
          tmp_files.current_description(t),
          tmp_files.generated_template(t),
          # tmp_files.generated_description(t),
        ]
      end.flatten
    end

    def normalise_file(f)
      d = JSON.parse(IO.read f)

      d = convert_description(d)

      n = StackNormaliser.new(true).normalise_stack(d)
      n = HashSorter.new.sort_hash n
      content = JSON.pretty_generate(n) + "\n"

      tmp = f + ".tmp"
      IO.write tmp, content
      File.rename tmp, f
    end

    # Eww. Doesn't really belong here?
    def convert_description(d)
      d["stacks"] or return d
      keys_to_title_case d
    end

    def keys_to_title_case(d)
      if d.kind_of? Hash
        d.entries.map {|k,v| [convert_key(k), keys_to_title_case(v)] }.to_h
      elsif d.kind_of? Array
        d.map {|v| keys_to_title_case v }
      else
        d
      end
    end

    def convert_key(k)
      k.split(/_/).
        map {|w| w[0].upcase + w[1..-1].downcase }.
        map {|w| w.sub(/^Arn(?=s$)/, "ARN") }.
        join ""
    end

  end

end
