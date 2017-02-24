module Spud

  class Stack
    attr_reader :name, :account_alias, :type, :region

    def initialize(name, type, account_alias, region)
      @name = name
      @account_alias = account_alias
      @type = type
      @region = region
    end

    def to_h
      {
        name: @name,
        account_alias: @account_alias,
        type: @type,
        region: @region
      }
    end
  end

  class Extensions
    attr_accessor :puller
    attr_accessor :generator
    attr_accessor :stack_name_suggester
    attr_accessor :pusher
    def initialize()
      @puller = DefaultPuller.new
      @generator = DefaultGenerator.new
      @stack_name_suggester = DefaultStackNameSuggester.new
      @pusher = DefaultPusher.new
    end
  end

  class Context

    JSON_FILE = "stack_names.json"

    attr_accessor :argv
    attr_accessor :scripts_dir
    attr_accessor :tmp_dir
    attr_reader :stacks
    attr_reader :config_set
    attr_reader :extensions
#    attr_accessor :stack_types
#    attr_accessor :stack_names

    def initialize
      @scripts_dir = File.expand_path("../../scripts/default", File.dirname(__FILE__))
      ENV["SPUD_DEFAULT_SCRIPTS_DIR"] = @scripts_dir
      @tmp_dir = File.join "tmp", "templates"
      @config_set = "default"
      @persisted_config = load_config
      @config = Spud.deep_copy(@persisted_config)
      @stacks = {}
      @extensions = Extensions.new
    end

    def config_set=(val)
      @config_set = val
      @stacks = {} # "<type>" => Stack object
      puts "config for this run: #{config}"
      config.each do |k, v|
        puts "creating stack item from #{k} // #{v}"
        if v.is_a?(Hash) then
          @stacks[k] = Stack.new(v["stack_name"], k, v["account_alias"], v["region"])
          puts "found a hash - decomposed to #{@stacks[k]}"

        else
          @stacks[k] = Stack.new(v, k, nil, nil)
          puts "found not-a hash - decomposed to #{@stacks[k]}"
        end
      end
      puts "stacks are now: #{@stacks}"
      regenerate_config
    end

    def config
      config_set.split(/\./).reduce(@config) do |c, k|
        c[k] ||= {}
      end
    end

    def save
      if @config != @persisted_config
        save_config @config
        @persisted_config = Spud.deep_copy(@config)
      end
    end

    def stack_types
      @stacks.map do |(k, stack)|
        stack.type
      end
    end

    def stack_types=(val)
      # val = ["<type>", ...]
      val.each do |type|
        if @stacks[type] then
          s = @stacks[type]
          @stacks[type] ||= Stack.new(s.name, type, s.account_alias, s.region)
        else
          @stacks[type] = Stack.new(nil, type, nil, nil)
        end
      end
      regenerate_config
    end

    def stack_names
      ret = {}
      @stacks.each do |(k, stack)|
        ret[k] = stack.name
      end
      puts "resolved stack names: #{ret}"
      ret
    end

    def stack_names=(val)
      puts "stack names: #{val}"
      # val = {"<type>" => "<name>", ...}
      val.entries.each do |(type, name)|
        if @stacks[type] then
          s = @stacks[type]
          @stacks[type] = Stack.new(name, type, s.account_alias, s.region)
        else
          @stacks[type] = Stack.new(name, type, nil, nil)
        end
      end
      regenerate_config
    end

    def to_h
      {
        scripts_dir: @scripts_dir,
        tmp_dir: @tmp_dir,
        config_set: @config_set,
        :stack_types => stack_types,
        :stack_names => stack_names,
        :argv => argv,
        persisted_config: @persisted_config,
        config: @config,
        stacks: @stacks
      }
    end

    def to_s
      to_h.to_s
    end

    private

    def regenerate_config
      @stacks.entries.each do |(type, stack)|
        puts "entry: #{type}, #{stack.to_h}"
        config[type] = {
          "stack_name" => stack.name,
          "region" => stack.region,
          "account_alias" => stack.account_alias
        }
      end
      @config = HashSorter.new.sort_hash(@config)
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

# vi: ts=2 sts=2 sw=2 et