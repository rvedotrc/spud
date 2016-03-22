module StackFetcher

  class StackFetcherMain

    attr_reader :stack_types

    def initialize(argv)
    end

    def run
      @stack_types = StackTypes.list
    end

  end

end
