require 'tempfile'

module StackFetcher

  class ScriptRunner

    attr_reader :cmd, :args

    def initialize(opts)
      @cmd = opts[:cmd] or raise "No command specified"
      @args = opts[:args] || []
    end

    def run!
      # stdin is tty
      # stdout is captured
      # stderr is tty
      # run, and raise an error if exit non-zero
      # return something with #output

      tmpfile = Tempfile.new('spud')
      begin
        tmpfile.unlink

        pid = Process.spawn(
          @cmd, *@args,
          in: ["/dev/null"],
          out: tmpfile.fileno,
        )
        Process.wait(pid)

        $?.success? or raise "Command #{cmd.inspect} failed (exit status #{$?.exitstatus})"

        tmpfile.rewind
        ScriptResult.new(tmpfile.read)
      ensure
        tmpfile.close
      end
    end

  end

  class ScriptResult

    attr_reader :output

    def initialize(output)
      @output = output
    end

  end

end
