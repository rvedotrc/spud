require 'spud'

describe Spud::ScriptRunner do

  it "passes argv and captures stdout" do
    tmpscript = Tempfile.new('spud-rspec')
    tmpscript.puts <<EOF
#!/bin/sh
for arg in "$@" ; do
  echo "arg=$arg"
done
EOF
    tmpscript.flush
    tmpscript.chmod 0755

    result = Spud::ScriptRunner.new(
      cmd: tmpscript.path,
      args: [ "a cat", "a big dog" ],
    ).run!

    expect(result.output).to eq("arg=a cat\narg=a big dog\n")
  end

  it "raises an exception if the command fails" do
    expect {
      Spud::ScriptRunner.new(
        cmd: "false",
      ).run!
    }.to raise_error /false.*failed/
  end

  it "does not use the shell" do
    p = ENV["PATH"]
    begin
      expect {
        ENV["PATH"] = "/bin"
        Spud::ScriptRunner.new(
          cmd: "sh -c true",
        ).run!
      }.to raise_error Errno::ENOENT
    ensure
      ENV["PATH"] = p
    end
  end

end
