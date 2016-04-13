require 'spud'

describe Spud::CloudformationLimits do

  def ok(s)
    expect(Spud::CloudformationLimits.valid_stack_name?(s)).to be_truthy
  end

  def not_ok(s)
    expect(Spud::CloudformationLimits.valid_stack_name?(s)).to be_falsy
  end

  it "should allow valid stack name" do
    ok "MyStackName"
    ok "my-stack-name"
  end

  it "should disallow invalid stack name" do
    not_ok ""
    not_ok "My Stack Name"
    not_ok(("Very" * (128/4)) + "Long")
  end

end
