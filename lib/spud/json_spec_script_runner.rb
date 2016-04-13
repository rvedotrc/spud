require 'tempfile'

module Spud

  class JsonSpecScriptRunner

    attr_reader :cmd, :spec

    def initialize(opts)
      @cmd = opts[:cmd] or raise "No command specified"
      @spec = opts[:spec] || {}
    end

    def run!
      # stdin is the spec, as json
      # stdout is tty
      # stderr is tty
      # run, and raise an error if exit non-zero
      # returns nothing

      content = JSON.generate(spec)

      tmpfile = Tempfile.new('spud')
      begin
        tmpfile.unlink
        tmpfile.write(content)
        tmpfile.rewind

        pid = Process.spawn(
          [ @cmd, @cmd ],
          in: tmpfile.fileno, # guaranteed to be a file, not e.g. a fifo
        )
        Process.wait(pid)

        $?.success? or raise "Command #{cmd.inspect} failed (exit status #{$?.exitstatus})"
      ensure
        tmpfile.close
      end

      nil
    end

  end

end
