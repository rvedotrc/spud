require 'json'

module Spud

  class Generator

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def generate_all
      run_script
      check_results
    end

    def run_script
      argv = context.argv
      stacks = context.stacks.reduce({}) do |memo, stack|
        memo[stack.type] = {
          type: stack.type,
          name: stack.name,
          region: stack.region,
          account_alias: stack.account_alias,
          template: tmp_files.get(:generated_template, stack.type).path,
          description: tmp_files.get(:generated_template, stack.type).path,
        }
        memo
      end

      context.extensions.generator.generate(context, stacks)
    end

    def check_results
      files = context.stack_types.map do |t|
        [
          tmp_files.get(:generated_template, t),
          # tmp_files.get(:generated_description, t),
        ]
      end.flatten

      files.each do |t|
        f = t.path
        begin
          t.discard!
          t.data
        rescue Errno::ENOENT => e
          $stderr.puts "Error: generator ran, but did not create #{f}"
          exit 1
        rescue JSON::ParserError => e
          if File.stat(f).size == 0
            $stderr.puts "Error: generator ran and created #{f}, but the file is empty"
          else
            $stderr.puts "Error: generator ran and created #{f}, but it does not contain valid JSON"
          end
          exit 1
        rescue Exception => e
          $stderr.puts "Error: generator ran, but there was an error checking #{f}: #{e}"
          exit 1
        end
      end
    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
