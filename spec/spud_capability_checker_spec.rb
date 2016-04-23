require 'spud'

describe Spud::CapabilityChecker do

  def a_template_with_resource_of_type(resource_type)
    a_file_with_data({
      "Resources" => {
        "MyResource" => { "Type" => resource_type }
      }
    }, "template")
  end

  def a_description_with_capabilities(capabilities)
    a_file_with_data({
      "Stacks" => [ {
        "Capabilities" => capabilities,
      } ],
    }, "description")
  end

  def a_file_with_data(data, description = "")
    a_tmp_file = double("a tmp file (#{description})")
    expect(a_tmp_file).to receive(:data).at_least(1).and_return(data)
    a_tmp_file
  end

  def make_checker(m)
    context = double("context")
    expect(context).to receive(:stack_types).and_return(m.keys.sort)

    tmp_files = double("tmp files")
    m.entries.each do |stack_type, template_and_description|
      t, d = template_and_description
      expect(tmp_files).to receive(:get).with(:next_description, stack_type).and_return(d)
      expect(tmp_files).to receive(:get).with(:next_template, stack_type).and_return(t)
    end

    Spud::CapabilityChecker.new(context, tmp_files)
  end

  it "iam not needed and not present" do
    template = a_template_with_resource_of_type("AWS::S3::Bucket")
    description = a_description_with_capabilities(["C"])
    expect(Spud::UserInteraction).not_to receive(:confirm_default_yes)
    expect(Spud::UserInteraction).not_to receive(:confirm_default_no)

    checker = make_checker({ "blue" => [ template, description ] })
    ok = checker.check?
    expect(ok).to be_truthy

    expect(description.data["Stacks"][0]["Capabilities"]).to eq(["C"])
  end

  it "iam not needed and is present" do
    template = a_template_with_resource_of_type("AWS::S3::Bucket")
    description = a_description_with_capabilities(["C", "CAPABILITY_IAM"])
    expect(Spud::UserInteraction).not_to receive(:confirm_default_yes)
    expect(Spud::UserInteraction).not_to receive(:confirm_default_no)

    checker = make_checker({ "blue" => [ template, description ] })
    ok = checker.check?
    expect(ok).to be_truthy

    expect(description.data["Stacks"][0]["Capabilities"]).to eq(["C", "CAPABILITY_IAM"])
  end

  it "iam needed and not present (yes)" do
    template = a_template_with_resource_of_type("AWS::IAM::User")
    description = a_description_with_capabilities(["C"])
    expect(Spud::UserInteraction).to receive(:confirm_default_yes) { true }
    expect(Spud::UserInteraction).not_to receive(:confirm_default_no)

    checker = make_checker({ "blue" => [ template, description ] })
    ok = checker.check?
    expect(ok).to be_truthy

    expect(description.data["Stacks"][0]["Capabilities"]).to eq(["C", "CAPABILITY_IAM"])
  end

  it "iam needed and not present (no)" do
    template = a_template_with_resource_of_type("AWS::IAM::User")
    description = a_description_with_capabilities(["C"])
    expect(Spud::UserInteraction).to receive(:confirm_default_yes) { false }
    expect(Spud::UserInteraction).not_to receive(:confirm_default_no)

    checker = make_checker({ "blue" => [ template, description ] })
    ok = checker.check?
    expect(ok).to be_falsy

    expect(description.data["Stacks"][0]["Capabilities"]).to eq(["C"])
  end

  it "iam needed and is present" do
    template = a_template_with_resource_of_type("AWS::IAM::User")
    description = a_description_with_capabilities(["C", "CAPABILITY_IAM"])
    expect(Spud::UserInteraction).not_to receive(:confirm_default_yes)
    expect(Spud::UserInteraction).not_to receive(:confirm_default_no)

    checker = make_checker({ "blue" => [ template, description ] })
    ok = checker.check?
    expect(ok).to be_truthy

    expect(description.data["Stacks"][0]["Capabilities"]).to eq(["C", "CAPABILITY_IAM"])
  end

end
