module StackFetcher

  class StackTypes

    attr_reader :context

    def initialize(context)
      @context = context
    end

    def list
      Dir.new("src").entries.reject {|s| s.start_with? "."}.sort
    end

  end

end
