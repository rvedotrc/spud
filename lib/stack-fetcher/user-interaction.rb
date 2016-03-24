module StackFetcher

  class UserInteraction

    def self.get_mandatory_text(opts)
      # :question (mandatory)
      # :prefill (may be nil)
      # return: text (single line, chomped)

      # Dead simple option.  TODO, use readline with history pre-fill.
      print opts[:question]
      if opts[:prefill]
        print " (e.g. #{opts[:prefill]})"
      end
      print ": "

      $stdin.readline.chomp
    end

  end

end
