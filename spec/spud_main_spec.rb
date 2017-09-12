require_relative 'capture_stdout'
require 'spud'

describe Spud::Main do

  def expect_help(argv)
    prepare = double(prepare)
    expect(Spud::Prepare).not_to receive(:new)
    expect(Spud::Apply).not_to receive(:new)

    r = CaptureStdout.run do
      expect do
        Spud::Main.new(argv).run
      end.to raise_error(SystemExit)
    end

    expect(r.output).to match(/^Usage: spud/)
    expect(r.output).to match(/Any ARGS are uninterpreted/)
  end

  def expect_return(argv)
    CaptureStdout.run do
      expect do
        Spud::Main.new(argv).run
      end.not_to raise_error
    end
  end

  it "runs prepare" do
    argv = %w[ prepare foo bar ]

    prepare = double(prepare)
    context = nil
    expect(Spud::Prepare).to receive(:new) {|c| context = c; prepare}
    expect(Spud::Apply).not_to receive(:new)
    expect(prepare).to receive(:run)

    expect_return argv

    expect(context.argv).to eq(%w[ foo bar ])
  end

  it "runs apply" do
    argv = %w[ apply foo bar ]

    prepare = double(prepare)
    context = nil
    expect(Spud::Apply).to receive(:new) {|c| context = c; prepare}
    expect(Spud::Prepare).not_to receive(:new)
    expect(prepare).to receive(:run)

    expect_return argv

    expect(context.argv).to eq(%w[ foo bar ])
  end

  it "shows help by default" do
    expect_help([])
  end

  it "supports 'spud help'" do
    expect_help(["help"])
  end

  it "supports 'spud --help'" do
    expect_help(["--help"])
  end

  def context_for_options(options)
    prepare = double(prepare)
    context = nil
    expect(Spud::Prepare).to receive(:new) {|c| context = c; prepare}
    expect(Spud::Apply).not_to receive(:new)
    expect(prepare).to receive(:run)
    argv = options + ["prepare"]
    expect_return argv
    context
  end

  it "supports -t" do
    context = context_for_options(%w[ -t x ])
    expect(context.tmp_dir).to eq("x")
  end

  it "supports --tmp-dir" do
    context = context_for_options(%w[ --tmp-dir x ])
    expect(context.tmp_dir).to eq("x")
  end

  it "supports -c" do
    context = context_for_options(%w[ -c x.y ])
    expect(context.config_set).to eq("x.y")
  end

  it "supports --config-set" do
    context = context_for_options(%w[ --config-set x.y ])
    expect(context.config_set).to eq("x.y")
  end

end
