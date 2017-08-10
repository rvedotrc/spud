require 'spud'

describe Spud::Context do

  def given_no_file
    expect(IO).to receive(:read).with(Spud::Context::JSON_FILE).and_raise(Errno::ENOENT)
  end

  def given_a_file(data)
    expect(IO).to receive(:read).with(Spud::Context::JSON_FILE).and_return(JSON.generate data)
  end

  def capture_save(c)
    data = nil
    expect(IO).to receive(:write) {|f, c| data = JSON.parse c}
    expect(File).to receive(:rename)
    c.save
    data
  end

  def verify_and_reset(*mocks)
    mocks.each {|mock| RSpec::Mocks.space.proxy_for(mock).verify}
    mocks.each {|mock| RSpec::Mocks.space.proxy_for(mock).reset}
  end

  it "should provide defaults" do
    given_no_file
    c = Spud::Context.new
    expect(c.tmp_dir).to eq("tmp/templates")
    expect(c.config_set).to eq("default")
    expect(c.config).to eq({})
  end

  it "saves config if modified" do
    given_no_file
    c = Spud::Context.new

    expect(IO).not_to receive(:write)
    c.save

    verify_and_reset IO

    c.config["baz"] = true

    data = capture_save c
    expect(data).to eq({ "default" => { "baz" => true } })

    verify_and_reset IO

    expect(IO).not_to receive(:write)
    c.save
  end

  it "uses config_set" do
    given_no_file
    c = Spud::Context.new
    c.config_set = "foo.bar"
    c.config["baz"] = true
    
    expect(c.config).to eq({ "baz" => true })

    data = capture_save c
    expect(data).to eq({ "foo" => { "bar" => { "baz" => true } } })
  end

  it "provides default extensions" do
    c = Spud::Context.new
    expect(c.extensions.generator).to respond_to(:generate)
    expect(c.extensions.puller).to respond_to(:fetch_stacks)
    expect(c.extensions.stack_name_suggester).to respond_to(:suggest_name)
    expect(c.extensions.pusher).to respond_to(:push_stacks)
  end

  it "defaults to no stack types" do
    given_no_file
    c = Spud::Context.new
    expect(c.stacks).to be_empty
  end

  it "generates nameless stack stubs" do
    given_no_file
    c = Spud::Context.new
    c.stack_types = %w[ foo bar ]
    expect(c.stacks).to eq([
      Spud::Stack.new(nil, 'foo', nil, nil, nil),
      Spud::Stack.new(nil, 'bar', nil, nil, nil),
    ])
  end

  it "ignores saved stacks that aren't in stack_types" do
    given_a_file({ "default" => {
      "bar" => "BarName",
    }, })
    c = Spud::Context.new
    c.stack_types = %w[ foo ]
    expect(c.stacks).to eq([
      Spud::Stack.new(nil, 'foo', nil, nil, nil),
    ])
  end

  it "loads stacks from stack_names.json, upgrading if necessary" do
    given_a_file({ "default" => {
      "bar" => "BarName",
      "baz" => {"stack_name" => "BazName", "account_alias" => "myaccount", "region" => "my-region-1"},
    }, })
    c = Spud::Context.new
    c.stack_types = %w[ foo bar baz ]
    expect(c.stacks).to eq([
      Spud::Stack.new(nil, 'foo', nil, nil, nil),
      Spud::Stack.new('BarName', 'bar', nil, nil, nil),
      Spud::Stack.new('BazName', 'baz', 'myaccount', 'my-region-1', nil),
    ])
  end

  it "saves stack names" do
    given_no_file
    c = Spud::Context.new
    c.stack_types = %w[ foo bar ]
    c.stacks.last.name = 'NameOfBar'

    data = capture_save c
    expect(data).to eq({"default"=>{
      "foo"=>{"account_alias"=>nil, "region"=>nil, "skip"=>false, "stack_name"=>nil},
      "bar"=>{"account_alias"=>nil, "region"=>nil, "skip"=>false, "stack_name"=>"NameOfBar"},
    }})
  end

  # Arbitrary choice to be honest, but let's test it
  it "does preserves old stack types" do
    given_a_file({
      "default" => { "foo" => "DefaultFooName" },
    })
    c = Spud::Context.new
    c.stack_types = %w[ bar ]
    data = capture_save c
    expect(data).to eq({"default"=>{
      "bar"=>{"account_alias"=>nil, "region"=>nil, "skip"=> false, "stack_name"=>nil},
      # foo is not upgraded to a hash, nor is it deleted
      "foo"=>"DefaultFooName"}
    })
  end

  # In current usage within spud, we always set the config_set (if at all)
  # once, *then* set stack_types (once).  Here we test other variations.

  it "respects config_set when handling stacks" do
    given_a_file({
      "default" => { "foo" => "DefaultFooName" },
      "other" => { "foo" => "OtherFooName" },
      "yet" => { "another" => { "foo" => "YetAnotherFooName" } },
    })

    c = Spud::Context.new
    c.stack_types = %w[ foo ]
    expect(c.stacks).to eq([
      Spud::Stack.new('DefaultFooName', 'foo', nil, nil, nil),
    ])

    c.config_set = 'other'
    expect(c.stacks).to eq([
      Spud::Stack.new('OtherFooName', 'foo', nil, nil, nil),
    ])

    c.config_set = 'yet.another'
    expect(c.stacks).to eq([
      Spud::Stack.new('YetAnotherFooName', 'foo', nil, nil, nil),
    ])
  end

  it "saves stack names as config_set is changed" do
    given_no_file

    c = Spud::Context.new
    c.config_set = 'set1'
    c.stack_types = %w[ foo ]
    c.stacks.first.name = 'Set1Foo'
    c.config_set = 'set2'
    c.stacks.first.name = 'Set2Foo'
    c.config_set = 'set.three'
    c.stacks.first.name = 'SetThreeFoo'

    data = capture_save c

    expect(data).to eq({
      "set1"=>{"foo"=>{"account_alias"=>nil, "region"=>nil, "skip"=>false, "stack_name"=>"Set1Foo"}},
      "set2"=>{"foo"=>{"account_alias"=>nil, "region"=>nil, "skip"=>false, "stack_name"=>"Set2Foo"}},
      "set"=>{"three"=>{"foo"=>{"account_alias"=>nil, "region"=>nil, "skip"=>false, "stack_name"=>"SetThreeFoo"}} },
    })
  end

end
