module StackFetcher

  class Context

    JSON_FILE = "stack_names.json"

    attr_accessor :argv
    attr_accessor :stack_types
    attr_accessor :stack_names
    attr_reader :config

    def initialize
      @persisted_config = load_config
      @config = deep_copy(@persisted_config)
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
