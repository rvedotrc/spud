module Spud

  class NormaliserRunner

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def normalise_all
      n = FileNormaliser.new
      files.each do |f|
        n.normalise_file f
      end
    end

    private

    def files
      context.stack_types.map do |t|
        [
          tmp_files.get(:current_template, t),
          tmp_files.get(:current_description, t),
          tmp_files.get(:generated_template, t),
          # tmp_files.get(:generated_description, t),
        ]
      end.flatten
    end

  end

end
