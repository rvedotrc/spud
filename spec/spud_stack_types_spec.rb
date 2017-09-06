require 'spud'

describe Spud::StackTypes do

  it "should work out the stack types" do
    dir = double("src dir")
    directories = ["src/foo", "src/foo2", "src/bar", "src/bar2"]
    expect(Dir).to receive(:new).with("src") { dir }
    expect(dir).to receive(:entries) { %w[ . .. foo foo2 bar bar2 zap .baz ] }
    allow(File).to receive(:directory?) do |arg|
      directories.include? arg
    end

    c = Spud::Context.new
    # foo: no config at all
    c.config['foo2'] = {} # config, but no 'skip'
    c.config['bar'] = { 'skip' => false }
    c.config['bar2'] = { 'skip' => true }

    stack_types = Spud::StackTypes.new(c).list
    expect(stack_types).to eq(%w[ bar foo foo2 ])
  end

end
