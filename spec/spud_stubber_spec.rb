require 'spud'

describe Spud::Stubber do

  it "creates a valid stub template" do
    data = Spud::Stubber.make_template
    t = Spud::StackNormaliser.new.normalise_stack(data)
    expect(t["AWSTemplateFormatVersion"]).to eq("2010-09-09")
    # Interestingly, the StackNormaliser normalises empty things to gone in
    # templates, but to empty arrays in descriptions.  Seems inconsistent.
    expect(t["Parameters"]).to eq(nil)
    expect(t["Resources"]).to eq(nil)

    expect(Spud::Stubber.is_stub_template?(t)).to be_truthy
    t["Resources"] = {"MyQueue" => {}}
    expect(Spud::Stubber.is_stub_template?(t)).to be_falsy
  end

  it "creates a valid stub description" do
    data = Spud::Stubber.make_description("foo")
    t = Spud::StackNormaliser.new.normalise_stack(data)
    expect(t["Stacks"][0]["StackName"]).to eq("foo")
    expect(t["Stacks"][0]["Parameters"]).to eq([])
    expect(t["Stacks"][0]["Tags"]).to eq([])

    expect(Spud::Stubber.is_stub_description?(t)).to be_truthy
    t["Stacks"][0]["StackId"] = "something"
    expect(Spud::Stubber.is_stub_description?(t)).to be_falsy
  end

end
