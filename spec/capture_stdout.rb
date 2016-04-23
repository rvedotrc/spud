require 'ostruct'
require 'tempfile'

class CaptureStdout

  def self.run
    old_stdout = $stdout
    tmpfile = Tempfile.new('spud')
    tmpfile.unlink

    begin
      $stdout = tmpfile
      value = yield
      tmpfile.rewind
      output = tmpfile.read
      OpenStruct.new(output: output, value: value)
    ensure
      $stdout = old_stdout
    end
  end

end
