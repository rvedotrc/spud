require 'spud'

describe Spud::StackTypes do

  it "should work out the stack types" do
    dir = double("src dir")
    expect(Dir).to receive(:new).with("src") { dir }
    expect(dir).to receive(:entries) { %w[ . .. foo bar .baz ] }

    stack_types = Spud::StackTypes.new(nil).list
    expect(stack_types).to eq(%w[ bar foo ])
  end

end
