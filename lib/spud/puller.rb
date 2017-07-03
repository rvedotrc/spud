require 'json'

module Spud

  class Puller

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def get_all
      run_script
      check_results
      add_stubs
    end

    def run_script
      stacks = context.stacks.reduce({}) do |memo, stack|
        memo[stack.type] = {
          type: stack.type,
          name: stack.name,
          region: stack.region,
          account_alias: stack.account_alias,
          template: tmp_files.get(:current_template, stack.type).path,
          description: tmp_files.get(:current_description, stack.type).path,
        }
        memo
      end

      context.extensions.puller.fetch_stacks(context, stacks)
    end

    def check_results
      files = context.stack_types.map do |t|
        [
          tmp_files.get(:current_template, t),
          tmp_files.get(:current_description, t),
        ]
      end.flatten

      files.each do |t|
        f = t.path
        begin
          t.discard!
          t.data
        rescue Errno::ENOENT => e
          $stderr.puts "Error: puller ran, but did not create #{f}"
          exit 1
        rescue JSON::ParserError => e
          if File.stat(f).size == 0
            $stderr.puts "Error: puller ran and created #{f}, but the file is empty"
          else
            $stderr.puts "Error: puller ran and created #{f}, but it does not contain valid JSON"
          end
          exit 1
        rescue Exception => e
          $stderr.puts "Error: puller ran, but there was an error checking #{f}: #{e}"
          exit 1
        end
      end
    end

    def add_stubs
      context.stacks.each do |stack|
        t = tmp_files.get(:current_template, stack.type)
        d = tmp_files.get(:current_description, stack.type)

        # puller should write '{}' to both files if the stack does
        # not yet exist.

        if t.data.empty? and d.data.empty?
          # New stack: create stubs
          t.data = Spud::Stubber.make_template
          d.data = Spud::Stubber.make_description(stack.name)
        elsif t.data.empty? != d.data.empty?
          $stderr.puts "Error: puller created partially-empty results for the #{stack.type} stack"
          exit 1
        end
      end
    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
