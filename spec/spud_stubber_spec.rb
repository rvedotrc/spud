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
  end

  it "creates a valid stub description" do
    data = Spud::Stubber.make_description("foo")
    t = Spud::StackNormaliser.new.normalise_stack(data)
    expect(t["Stacks"][0]["StackName"]).to eq("foo")
    # Lack of a StackId is what marks this as a stub
    expect(t["Stacks"][0].has_key? "StackId").to be_falsy
    expect(t["Stacks"][0]["Parameters"]).to eq([])
    expect(t["Stacks"][0]["Tags"]).to eq([])
  end

end
