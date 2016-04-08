require 'fileutils'

module StackFetcher

  class TmpFiles

    attr_reader :context

    def initialize(context)
      @context = context
    end

    def clean!
      ensure_tmp_dir
      FileUtils.rm_f all
    end

    def copy_current_to_next
      context.stack_types.each do |stack_type|
        FileUtils.cp current_template(stack_type), next_template(stack_type)
        FileUtils.cp current_description(stack_type), next_description(stack_type)
      end
    end

    def current_template(type)
      make_path "template-#{type}.#{env}.current.json"
    end

    def generated_template(type)
      make_path "template-#{type}.#{env}.generated.json"
    end

    def next_template(type)
      make_path "template-#{type}.#{env}.next.json"
    end

    def current_description(type)
      make_path "description-#{type}.#{env}.current.json"
    end

    def generated_description(type)
      make_path "description-#{type}.#{env}.generated.json"
    end

    def next_description(type)
      make_path "description-#{type}.#{env}.next.json"
    end

    private

    def all
      context.stack_types.map do |type|
        [
          current_template(type),
          current_description(type),
          generated_template(type),
          generated_description(type),
          next_template(type),
          next_description(type),
        ]
      end.flatten
    end

    def env
      # FIXME
      context.argv.last || "default"
    end

    def tmp_dir
      File.join "tmp", "templates"
    end

    def ensure_tmp_dir
      FileUtils.mkdir_p tmp_dir
    end

    def make_path(basename)
      File.join tmp_dir, basename
    end

  end

end
