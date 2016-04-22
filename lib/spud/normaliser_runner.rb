module Spud

  class NormaliserRunner

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def normalise(stages)
      n = FileNormaliser.new
      files(stages).each do |f|
        n.normalise_file f
      end
    end

    private

    def files(stages)
      context.stack_types.map do |t|
        stages.map do |stage|
          tmp_files.get(stage, t)
        end
      end.flatten
    end

  end

end
