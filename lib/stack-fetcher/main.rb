module StackFetcher

  class Main

    attr_reader :context

    def initialize(argv)
      @context = Context.new
      @context.argv = argv.dup.freeze
    end

    def run
      @context.stack_types = StackTypes.new(context).list
      @context.stack_names = StackFinder.new(context).get_names
      p @context
      context.save
    end

  end

end
