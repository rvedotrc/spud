require 'spud'

describe Spud do

  def sample_in
    {
      "foo" => [
        true,
        nil,
        "Seven",
        { "a" => "hash" },
      ],
    }
  end

  def get_i_o
    i = sample_in
    o = Spud.deep_copy(i)
    expect(o).to eq(i)
    [ i, o ]
  end

  it "should deep copy hashes" do
    i, o = get_i_o
    i["foo"].last["new key"] = "new value"
    expect(i).not_to eq(o)
  end

  it "should deep copy arrays" do
    i, o = get_i_o
    i["foo"] << 99
    expect(i).not_to eq(o)
  end

end
