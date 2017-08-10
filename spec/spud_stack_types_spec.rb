require 'spud'

describe Spud::StackTypes do

  it "should work out the stack types" do
    dir = double("src dir")
    directories = ["src/foo", "src/bar"]
    expect(Dir).to receive(:new).with("src") { dir }
    expect(dir).to receive(:entries) { %w[ . .. foo bar zap .baz ] }
    allow(File).to receive(:directory?) do |arg|
      directories.include? arg
    end

    c = Spud::Context.new
    c.config['foo'] = { 'skip' => false }
    c.config['bar'] = { 'skip' => false }

    stack_types = Spud::StackTypes.new(c).list
    expect(stack_types).to eq(%w[ bar foo ])
  end

end
