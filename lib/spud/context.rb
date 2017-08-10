module Spud

  class Stack
    attr_reader :type
    attr_accessor :account_alias, :name, :region, :skip

    def initialize(name, type, account_alias, region, skip)
      @name = name
      @account_alias = account_alias
      @type = type
      @region = region
      @skip = skip
    end

    def to_h
      {
        name: @name,
        account_alias: @account_alias,
        type: @type,
        region: @region,
        skip: @skip
      }
    end

    def ==(other)
      if other.is_a? Stack
        to_h == other.to_h
      else
        false
      end
    end
  end

  class Extensions
    attr_accessor :puller
    attr_accessor :generator
    attr_accessor :stack_name_suggester
    attr_accessor :pusher
    attr_accessor :account_alias_prompter
    def initialize
      @puller = Spud::Ext::DefaultPuller.new
      @generator = Spud::Ext::DefaultGenerator.new
      @stack_name_suggester = Spud::Ext::DefaultStackNameSuggester.new
      @pusher = Spud::Ext::DefaultPusher.new
      @account_alias_prompter = nil
    end
  end

  class Context

    JSON_FILE = "stack_names.json"

    attr_accessor :argv
    attr_accessor :tmp_dir
    attr_reader :stack_types
    attr_reader :config_set
    attr_reader :extensions

    def initialize
      @tmp_dir = File.join "tmp", "templates"
      @persisted_config = load_config
      @config = Spud.deep_copy(@persisted_config)
      @stacks = []
      @stack_types = []
      @extensions = Extensions.new
      @config_set = 'default'
      load_stacks
    end

    def stacks
      @stacks.each.to_a
    end

    def config_set=(val)
      save_stacks
      @config_set = val
      load_stacks
    end

    def stack_types=(types)
      @stack_types = types
      load_stacks
    end

    def config
      config_set.split(/\./).reduce(@config) do |c, k|
        c[k] ||= {}
      end
    end

    def save
      save_stacks
      if @config != @persisted_config
        save_config @config
        @persisted_config = Spud.deep_copy(@config)
      end
    end

    # FIXME: untested
    def to_h
      {
        tmp_dir: @tmp_dir,
        config_set: @config_set,
        :argv => argv,
        persisted_config: @persisted_config,
        config: @config,
        stacks: @stacks,
      }
    end

    # FIXME: untested
    def to_s
      to_h.to_s
    end

    private

    def load_stacks
      @stacks = stack_types.map do |type|
        v = config[type]

        unless v.is_a? Hash
          v = { "stack_name" => v }
        end

        # TODO: what does having an account_alias actually mean? What does
        # it *do*? What does it mean /not/ to have have one?
        # TODO ditto for region
        Stack.new(v["stack_name"], type, v["account_alias"], v["region"], v["skip"])
      end
    end

    def save_stacks
      @stacks.each do |stack|
        config[stack.type] = {
          "stack_name" => stack.name,
          "region" => stack.region,
          "account_alias" => stack.account_alias,
          "skip" => stack.skip ? true : false,
        }
      end
    end

    def load_config
      begin
        JSON.parse(IO.read JSON_FILE)
      rescue Errno::ENOENT
        {}
      end
    end

    def save_config(data)
      data = HashSorter.new.sort_hash(data)
      tmp = JSON_FILE + ".tmp"
      IO.write(tmp, JSON.pretty_generate(data)+"\n")
      File.rename tmp, JSON_FILE
    end

  end

end

# vi: ts=2 sts=2 sw=2 et
