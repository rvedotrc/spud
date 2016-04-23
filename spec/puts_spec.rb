require_relative 'capture_stdout'

describe CaptureStdout do

  it "should capture puts" do
    t = CaptureStdout.run do
      puts "foo", "bar"
      7
    end

    expect(t.output).to eq("foo\nbar\n")
    expect(t.value).to eq(7)
  end

end
