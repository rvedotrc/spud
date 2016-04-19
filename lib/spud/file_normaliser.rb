module Spud

  class FileNormaliser

    def normalise_file(f)
      d = f.data
      d = convert_description(d)
      n = StackNormaliser.new(true).normalise_stack(d)
      n = HashSorter.new.sort_hash n
      f.data = n

      # FIXME the flush is a hack – for when the data doesn't change, but we
      # want to ensure the file on disk is pretty-formatted.
      f.flush!
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
