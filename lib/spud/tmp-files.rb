require 'fileutils'

module Spud

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
      make_path "template-#{type}.current.json"
    end

    def generated_template(type)
      make_path "template-#{type}.generated.json"
    end

    def next_template(type)
      make_path "template-#{type}.next.json"
    end

    def current_description(type)
      make_path "description-#{type}.current.json"
    end

    def generated_description(type)
      make_path "description-#{type}.generated.json"
    end

    def next_description(type)
      make_path "description-#{type}.next.json"
    end

    def current_generated_next_shell(type)
      Shellwords.shellescape(context.tmp_dir) +
        "/" +
        "template-#{Shellwords.shellescape type}.{current,generated,next}.json"
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

    def ensure_tmp_dir
      FileUtils.mkdir_p context.tmp_dir
    end

    def make_path(basename)
      File.join context.tmp_dir, basename
    end

  end

end
