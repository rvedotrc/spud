module Spud

  class Context

    JSON_FILE = "stack_names.json"

    attr_accessor :argv
    attr_accessor :scripts_dir
    attr_accessor :tmp_dir
    attr_accessor :config_set
    attr_accessor :stack_types
    attr_accessor :stack_names

    def initialize
      @scripts_dir = File.expand_path("../../scripts/default", File.dirname(__FILE__))
      # FIXME find a cleaner solution
      ENV["SPUD_DEFAULT_SCRIPTS_DIR"] = @scripts_dir
      @tmp_dir = File.join "tmp", "templates"
      @config_set = "default"
      @persisted_config = load_config
      @config = deep_copy(@persisted_config)
    end

    def config
      config_set.split(/\./).reduce(@config) do |c, k|
        c[k] ||= {}
      end
    end

    def save
      if @config != @persisted_config
        save_config @config
        @persisted_config = deep_copy(@config)
      end
    end

    private

    def deep_copy(data)
      JSON.parse(JSON.generate data)
    end

    def load_config
      begin
        JSON.parse(IO.read JSON_FILE)
      rescue Errno::ENOENT
        {}
      end
    end

    def save_config(data)
      tmp = JSON_FILE + ".tmp"
      IO.write(tmp, JSON.pretty_generate(data)+"\n")
      File.rename tmp, JSON_FILE
    end

  end

end
