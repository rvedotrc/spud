require 'spud'

describe Spud::JsonFile do

  A_PATH = "some-file.json"

  def normalised_form_of(data)
    JSON.pretty_generate(data) + "\n"
  end

  def squished_form_of(data)
    JSON.generate(data)
  end

  def verify_and_reset(*mocks)
    mocks.each {|mock| RSpec::Mocks.space.proxy_for(mock).verify}
    mocks.each {|mock| RSpec::Mocks.space.proxy_for(mock).reset}
  end

  it "initialises to an unloaded state" do
    expect(JSON).not_to receive(:parse)
    t = Spud::JsonFile.new(A_PATH)
    expect(t.loaded?).to be_falsy
    expect(t.dirty?).to be_falsy
  end

  it "throws an error if no file" do
    t = Spud::JsonFile.new(A_PATH)
    expect(IO).to receive(:read).with(A_PATH).and_raise(Errno::ENOENT)
    expect {
      t.data
    }.to raise_error(Errno::ENOENT)
  end

  it "loads data if there is a file" do
    t = Spud::JsonFile.new(A_PATH)
    expect(IO).to receive(:read).with(A_PATH).and_return('[1,2,3]')
    expect(t.data).to eq([1,2,3])
  end

  it "supports data=" do
    t = Spud::JsonFile.new(A_PATH)
    t.data = [1,2,3]
    expect(t.data).to eq([1,2,3])
    expect(t.dirty?).to be_truthy
  end

  it "supports dirty? and discard!" do
    t = Spud::JsonFile.new(A_PATH)
    expect(IO).to receive(:read).exactly(2).with(A_PATH).and_return(normalised_form_of([1,2,3]))
    expect(t.data).to eq([1,2,3])
    expect(t.dirty?).to be_falsy

    t.data[-1] = 4
    expect(t.data).to eq([1,2,4])
    expect(t.dirty?).to be_truthy

    t.discard!
    expect(t.data).to eq([1,2,3])
    expect(t.dirty?).to be_falsy
  end

  def expect_write
    r = nil
    expect(IO).to receive(:write) {|path, content| r = content}
    expect(File).to receive(:rename)
    yield
    verify_and_reset IO, File
    JSON.parse r
  end

  def expect_no_write
    expect(IO).not_to receive(:write)
    yield
    verify_and_reset IO
  end

  it "flushes iff dirty" do
    t = Spud::JsonFile.new(A_PATH)
    t.data = [1,2,3]
    expect(t.dirty?).to be_truthy

    written = expect_write { t.flush }
    expect(t.dirty?).to be_falsy
    expect(written).to eq([1,2,3])

    expect_no_write { t.flush }
    expect(t.dirty?).to be_falsy

    t.data << 4
    expect(t.dirty?).to be_truthy
    written = expect_write { t.flush }
    expect(t.dirty?).to be_falsy
    expect(written).to eq([1,2,3,4])
  end

  it "supports flush!" do
    t = Spud::JsonFile.new(A_PATH)
    t.data = [1,2,3]
    expect_write { t.flush }

    expect_no_write { t.flush }
    expect_write { t.flush! }
  end

  it "supports delete!" do
    expect(IO).to receive(:read).with(A_PATH).and_return('[1,2,3]')
    t = Spud::JsonFile.new(A_PATH)
    t.data
    expect(t.loaded?).to be_truthy

    expect(FileUtils).to receive(:rm_f).with(A_PATH)
    t.delete!
    expect(t.loaded?).to be_falsy
  end

  it "loads as clean if formatted correctly" do
    expect(IO).to receive(:read).with(A_PATH).and_return(normalised_form_of([1,2,3]))
    t = Spud::JsonFile.new(A_PATH)
    t.data
    expect(t.dirty?).to be_falsy
  end

  it "loads as dirty if not formatted correctly" do
    expect(IO).to receive(:read).with(A_PATH).and_return(squished_form_of([1,2,3]))
    t = Spud::JsonFile.new(A_PATH)
    t.data
    expect(t.dirty?).to be_truthy
  end

  it "marks as dirty if keys are reordered" do
    out_of_order = {"b"=>2,"a"=>1}
    in_order = {"a"=>1,"b"=>2}
    expect(out_of_order).to eq(in_order)

    expect(IO).to receive(:read).with(A_PATH).and_return(normalised_form_of(out_of_order))
    t = Spud::JsonFile.new(A_PATH)
    t.data
    expect(t.dirty?).to be_falsy
    t.data = in_order
    expect(t.dirty?).to be_truthy
  end

end
