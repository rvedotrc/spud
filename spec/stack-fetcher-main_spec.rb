require_relative "../lib/stack-fetcher"

describe StackFetcher::StackFetcherMain do

  it "should work out the stack types" do
    expect(StackFetcher::StackTypes).to receive(:list) { %w[ bar foo ] }
    sf = StackFetcher::StackFetcherMain.new([])
    sf.run
    expect(sf.stack_types).to eq(%w[ bar foo ])
  end

end
