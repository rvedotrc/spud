module StackFetcher

  class Main

    attr_reader :context, :tmp_files

    def initialize(argv)
      @context = Context.new
      @context.argv = argv.dup.freeze
    end

    def run
      @context.stack_types = StackTypes.new(context).list
      @context.stack_names = StackFinder.new(context).get_names
      @tmp_files = TmpFiles.new(@context)
      @tmp_files.clean!
      Puller.new(context, tmp_files).get_all
      Generator.new(context, tmp_files).generate_all
      NormaliserRunner.new(context, tmp_files).normalise_all
      p @context
      context.save
    end

  end

end
