require 'hash_sorter'

describe HashSorter do

  def did_a_sort(hash_in, hash_out)
    expect(hash_out).to eq(hash_in)
    expect(hash_out.keys).not_to eq(hash_in.keys)
    expect(hash_out.keys).to eq(hash_in.keys.sort)
  end

  it "sorts hash keys" do
    i = { "foo"=>3, "bar"=>4, "baz"=>5 }
    o = HashSorter.new.sort_hash(i)
    did_a_sort(i, o)
  end

  it "does not sort arrays" do
    i = [ 7,3,5 ]
    o = HashSorter.new.sort_hash(i)
    expect(o).to eq(i)
    expect(o).not_to eq(o.sort)
  end

  it "sorts deeply" do
    i = {
      "foo" => [
        { "red" => 1, "green" => 2 },
        { "red" => 3, "blue" => 4 },
      ],
      "bar" => {
        "Green" => [],
        "Blue" => {},
      }
    }
    o = HashSorter.new.sort_hash(i)
    did_a_sort(i, o)
    did_a_sort(i["foo"][0], o["foo"][0])
    did_a_sort(i["foo"][1], o["foo"][1])
    did_a_sort(i["bar"], o["bar"])
  end

end
