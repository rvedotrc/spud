require 'json'

module StackFetcher

  class Puller

    attr_reader :context, :tmp_files

    def initialize(context, tmp_files)
      @context = context
      @tmp_files = tmp_files
    end

    def get_all
      run_script
      check_results
    end

    def run_script
      spec = {
        argv: context.argv,
        stacks: context.stack_types.each_with_object({}) do |t, h|
          h[t] = {
            name: context.stack_names[t],
            template: tmp_files.current_template(t),
            description: tmp_files.current_description(t),
          }
        end,
      }

      # s-f can provide a default implementation (but it can know nothing about
      # credentials, other than what's already in the environment).
      JsonSpecScriptRunner.new(
        cmd: File.join(context.scripts_dir, "retrieve-stacks"),
        spec: spec,
      ).run!
    end

    def check_results
      # FIXME what is the required behaviour (of the external script) if the
      # stack doesn't yet exist? How do we represent that in our state (in the
      # tmp dir)?

      # FIXME what is the expected format of the description file?
      # e.g. stack_name vs StackName; include the Stacks [ ... ] wrapper or
      # not?

      files = context.stack_types.map do |t|
        [
          tmp_files.current_template(t),
          tmp_files.current_description(t),
        ]
      end.flatten

      files.each do |f|
        begin
          data = JSON.parse(IO.read f)
        rescue Errno::ENOENT => e
          $stderr.puts "Error: retrieve-stacks script ran, but did not create #{f}"
          exit 1
        rescue JSON::ParserError => e
          if File.stat(f).size == 0
            $stderr.puts "Error: retrieve-stacks script ran and created #{f}, but the file is empty"
          else
            $stderr.puts "Error: retrieve-stacks script ran and created #{f}, but it does not contain valid JSON"
          end
          exit 1
        rescue Exception => e
          $stderr.puts "Error: retrieve-stacks script ran, but there was an error checking #{f}: #{e}"
          exit 1
        end
      end
    end

  end

end
