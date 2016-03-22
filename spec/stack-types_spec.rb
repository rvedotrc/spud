require_relative "../lib/stack-fetcher"

describe StackFetcher::StackTypes do

  it "should work out the stack types" do
    expect(Dir).to receive(:glob).with("src/*") { %w[ . .. foo bar .baz ] }
    stack_types = StackFetcher::StackTypes.list
    expect(stack_types).to eq(%w[ bar foo ])
  end

end
