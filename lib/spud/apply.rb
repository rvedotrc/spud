module Spud

  class Apply

    attr_reader :context, :tmp_files

    def initialize(context)
      @context = context
    end

    def run
      # By the time we get here, global options and the verb "apply" have
      # already been consumed from argv.

      @context.stack_types = StackTypes.new(context).list

      if @context.stack_types.empty?
        puts "No stack types defined - nothing to do"
        return
      end

      @tmp_files = TmpFiles.new(@context)

      ok = checks_ok?
      NormaliserRunner.new(context, tmp_files).normalise([ :next_description, :next_template ])
      tmp_files.flush
      ok or exit 3

      update_or_create
    end

    def checks_ok?
      ParameterCheckerOld.new(context, tmp_files).check? \
        and CapabilityChecker.new(context, tmp_files).check?
    end

    def update_or_create
      context.stack_types.each do |stack_type|
        Updater.new(context, tmp_files, stack_type).run
      end
    end

  end

end
