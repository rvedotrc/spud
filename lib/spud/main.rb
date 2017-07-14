require 'optparse'

module Spud

  class Main

    attr_reader :context

    def initialize(argv, context = nil)
      @context = context || Context.new
      @context.argv = argv.dup
    end

    def run
      read_options

      verb = context.argv.shift

      case verb
      when nil, "help"
        show_help
      when "prepare"
        Prepare.new(context).run
      when "apply"
        Apply.new(context).run
      else
        $stderr.puts "Unknown invocation #{verb.inspect}"
        show_help
        exit 2
      end
    end

    def read_options
      opts_parser = OptionParser.new do |opts|
        opts.banner = <<'EOF'

Usage: spud [GLOBAL-OPTIONS] prepare [ARGS ...]
Usage: spud [GLOBAL-OPTIONS] apply [ARGS ...]
Usage: spud help

EOF
        opts.on("-t", "--tmp-dir=DIR", "Working files directory (default: #{context.tmp_dir})") do |v|
          context.tmp_dir = v
        end
        opts.on("-c", "--config-set=KEY", "Which configuration set to use (default: #{context.config_set.inspect}") do |v|
          context.config_set = v
        end
        opts.separator <<'EOF'

Any ARGS are uninterpreted by spud but made available to extensions.

The working files directory (default: #{context.tmp_dir}) will be created
(like "mkdir -p") on startup, and is NOT cleaned up on exit.

--config-set=KEY can be used to store several independent sets of
configuration (in "stack_names.json").  For example if you have "int", "test"
and "live" environments, you could use --config-set=int (etc).  If the KEY
contains dots then these are interpreted as JSON object key separators.

EOF
      end

      begin
        opts_parser.parse! context.argv
      rescue OptionParser::InvalidOption => e
        $stderr.puts e
        show_help
        exit 2
      end
    end

    def show_help
      context.argv = ["--help"]
      read_options
    end

  end

end
