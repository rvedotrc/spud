require 'fileutils'

module Spud

  class TmpFiles

    attr_reader :context

    def initialize(context)
      @context = context
      raise "No stack_types" if context.stack_types.nil?
      @files = context.stack_types.each_with_object({}) do |t, h|
        h[t] = files_for_type t
      end
    end

    def clean!
      ensure_tmp_dir
      files.each {|f| f.delete!}
    end

    def flush
      files.each {|f| f.flush if f.loaded?}
    end

    def get(sym, type)
      @files[type][sym]
    end

    def copy_current_to_next
      context.stack_types.each do |t|
        get(:next_template, t).data = get(:current_template, t).data
        get(:next_description, t).data = get(:current_description, t).data
      end
    end

    def current_generated_next_shell(type)
      Shellwords.shellescape(context.tmp_dir) +
        "/" +
        "template-#{Shellwords.shellescape type}.{current,generated,next}.json"
    end

    private

    def files
      @files.values.map(&:values).flatten
    end

    def files_for_type(t)
      {
        current_template: tmpfile("template-#{t}.current.json"),
        current_description: tmpfile("description-#{t}.current.json"),
        generated_template: tmpfile("template-#{t}.generated.json"),
        generated_description: tmpfile("description-#{t}.generated.json"),
        next_template: tmpfile("template-#{t}.next.json"),
        next_description: tmpfile("description-#{t}.next.json"),
      }
    end

    def tmpfile(basename)
      JsonFile.new(make_path(basename))
    end

    def ensure_tmp_dir
      FileUtils.mkdir_p context.tmp_dir
    end

    def make_path(basename)
      File.join context.tmp_dir, basename
    end

  end

end
