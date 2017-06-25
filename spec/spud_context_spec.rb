require 'spud'

describe Spud::Context do

  def verify_and_reset(*mocks)
    mocks.each {|mock| RSpec::Mocks.space.proxy_for(mock).verify}
    mocks.each {|mock| RSpec::Mocks.space.proxy_for(mock).reset}
  end

  it "should provide defaults" do
    expect(IO).to receive(:read).with(Spud::Context::JSON_FILE) { raise Errno::ENOENT }
    c = Spud::Context.new
    expect(c.tmp_dir).to eq("tmp/templates")
    expect(c.scripts_dir).to end_with("/scripts/default")
    expect(File.exist?( c.scripts_dir + "/generate-stacks" )).to be_truthy
    expect(c.config_set).to eq("default")
    expect(c.config).to eq({})
  end

  it "provides SPUD_DEFAULT_SCRIPTS_DIR" do
    c = Spud::Context.new
    expect(ENV["SPUD_DEFAULT_SCRIPTS_DIR"]).to eq(c.scripts_dir)
  end

  it "saves config if modified" do
    expect(IO).to receive(:read).with(Spud::Context::JSON_FILE) { raise Errno::ENOENT }
    c = Spud::Context.new

    expect(IO).not_to receive(:write)
    c.save

    verify_and_reset IO

    c.config["baz"] = true
    data = nil
    expect(IO).to receive(:write) {|f, c| data = JSON.parse c}
    expect(File).to receive(:rename)
    c.save
    expect(data).to eq({ "default" => { "baz" => true } })

    verify_and_reset IO

    expect(IO).not_to receive(:write)
    c.save
  end

  it "uses config_set" do
    expect(IO).to receive(:read).with(Spud::Context::JSON_FILE) { raise Errno::ENOENT }
    c = Spud::Context.new
    c.config_set = "foo.bar"
    c.config["baz"] = true
    
    expect(c.config).to eq({ "baz" => true })

    data = nil
    expect(IO).to receive(:write) {|f, c| data = JSON.parse c}
    expect(File).to receive(:rename)
    c.save
    expect(data).to eq({ "foo" => { "bar" => { "baz" => true } } })
  end

  it "provides default extensions" do
    c = Spud::Context.new
    expect(c.extensions.generator).to respond_to(:generate)
    expect(c.extensions.puller).to respond_to(:fetch_stacks)
    expect(c.extensions.stack_name_suggester).to respond_to(:suggest_name)
    expect(c.extensions.pusher).to respond_to(:push_stacks)
  end

end
