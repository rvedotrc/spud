module Spud

  class StackTypes

    attr_reader :context

    def initialize(context)
      @context = context
    end

    def list
      Dir.new("src").entries
        .reject {|s| s.start_with? "."}
        .keep_if {|s| File.directory?("src/#{s}")}
        .sort
    end

  end

end
