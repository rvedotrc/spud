require 'spud'

describe Spud::JsonSpecScriptRunner do

  it "should supply the data as JSON on stdin" do
    spec_in = { "a" => "b", "c" => nil }

    tmpout = Tempfile.new('spud-rspec')

    tmpscript = Tempfile.new('spud-rspec')
    tmpscript.puts <<EOF
#!/bin/sh
cat > #{Shellwords.shellescape tmpout.path}
EOF
    tmpscript.flush
    tmpscript.chmod 0755

    Spud::JsonSpecScriptRunner.new(
      cmd: tmpscript.path,
      spec: spec_in,
    ).run!

    tmpout.rewind
    content = tmpout.read
    spec_received = JSON.parse(content)
    expect(spec_received).to eq(spec_in)
  end

  it "runs with no ARGV" do
    tmpout = Tempfile.new('spud-rspec')

    tmpscript = Tempfile.new('spud-rspec')
    tmpscript.puts <<EOF
#!/bin/sh
echo $# > #{Shellwords.shellescape tmpout.path}
EOF
    tmpscript.flush
    tmpscript.chmod 0755

    Spud::JsonSpecScriptRunner.new(
      cmd: tmpscript.path,
    ).run!

    tmpout.rewind
    content = tmpout.read
    expect(content).to eq("0\n")
  end

  it "should set stdin to be a regular file" do
    tmpout = Tempfile.new('spud-rspec')

    tmpscript = Tempfile.new('spud-rspec')
    tmpscript.puts <<EOF
#!/bin/sh
perl -le 'print "OK" if -f "/dev/stdin"' > #{Shellwords.shellescape tmpout.path}
EOF
    tmpscript.flush
    tmpscript.chmod 0755

    Spud::JsonSpecScriptRunner.new(
      cmd: tmpscript.path,
    ).run!

    tmpout.rewind
    content = tmpout.read
    expect(content).to eq("OK\n")
  end

  it "raises an exception if the command fails" do
    expect {
      Spud::JsonSpecScriptRunner.new(
        cmd: "false",
      ).run!
    }.to raise_error /false.*failed/
  end

  it "does not use the shell" do
    p = ENV["PATH"]
    begin
      expect {
        ENV["PATH"] = "/bin"
        Spud::JsonSpecScriptRunner.new(
          cmd: "sh -c true",
        ).run!
      }.to raise_error Errno::ENOENT
    ensure
      ENV["PATH"] = p
    end
  end

end
