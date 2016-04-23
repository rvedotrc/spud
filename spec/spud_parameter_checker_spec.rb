require 'spud'

describe Spud::ParameterChecker do

  def a_template_with_params(p)
    p2 = p.entries.map do |k, default|
      h = {"Type" => "String"}
      h["Default"] = default unless default.nil?
      [ k, h ]
    end.to_h

    a_file_with_data({
      "Parameters" => p2,
    }, "template")
  end
  
  def a_description_with_params(p)
    p2 = p.entries.map do |k, value|
      { "ParameterKey" => k, "ParameterValue" => value }
    end

    a_file_with_data({
      "Stacks" => [ {
        "Parameters" => p2,
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

    Spud::ParameterChecker.new(context, tmp_files)
  end

  it "handles when everything is fine" do
    template = a_template_with_params({ "foo" => "f", "bar" => "b", "nodef" => nil})
    description = a_description_with_params({ "foo" => "f", "bar" => "b", "nodef" => "xxx" })
    checker = make_checker({ "blue" => [ template, description ] })
    result = checker.check

    expect(result.to_h).to eq({ "blue" => {} })
    expect(result.stop?).to be_falsy

    text = result.render
    expect(text).to eq("")
  end

  it "finds differences from the defaults" do
    template = a_template_with_params({ "foo" => "f", "bar" => "b", "nodef" => nil})
    description = a_description_with_params({ "foo" => "f", "bar" => "b2", "nodef" => "xxx" })
    checker = make_checker({ "blue" => [ template, description ] })
    result = checker.check

    m = { changes_from_defaults: { "bar" => [ "b", "b2" ] } }
    expect(result.to_h).to eq({ "blue" => m })
    expect(result.stop?).to be_falsy

    text = result.render
    expect(text).to match(/\bbar\b.*\bb\b.*\bb2\b/)
  end

  it "finds removed parameters" do
    template = a_template_with_params({ "bar" => "b" })
    description = a_description_with_params({ "foo" => "f", "bar" => "b", "aaa" => "7" })
    checker = make_checker({ "blue" => [ template, description ] })
    result = checker.check

    m = { removed_parameters: %w[ aaa foo ] }
    expect(result.to_h).to eq({ "blue" => m })
    expect(result.stop?).to be_truthy

    expect(description.data["Stacks"][0]["Parameters"]).to eq([ {"ParameterKey"=>"bar", "ParameterValue" => "b"} ])

    text = result.render
    expect(text).to match(/aaa foo/)
  end

  it "finds added parameters" do
    template = a_template_with_params({ "foo" => "f", "bar" => "b", "aaa" => "a" })
    description = a_description_with_params({ "bar" => "b" })
    checker = make_checker({ "blue" => [ template, description ] })
    result = checker.check

    m = { added_parameters: %w[ aaa foo ] }
    expect(result.to_h).to eq({ "blue" => m })
    expect(result.stop?).to be_truthy

    expect(description.data["Stacks"][0]["Parameters"]).to eq([
      {"ParameterKey"=>"aaa", "ParameterValue" => "a"},
      {"ParameterKey"=>"bar", "ParameterValue" => "b"},
      {"ParameterKey"=>"foo", "ParameterValue" => "f"},
    ])

    text = result.render
    expect(text).to match(/aaa foo/)
  end

  it "finds parameters with nil or missing value" do
    template = a_template_with_params({ "existing" => nil, "new" => nil })
    description = a_description_with_params({ "existing" => nil })
    description.data["Stacks"][0]["Parameters"] << { "ParameterKey" => "new" }

    checker = make_checker({ "blue" => [ template, description ] })
    result = checker.check

    # Both pre-existing parameters, and new ones
    m = { no_value_parameters: %w[ existing new ] }
    expect(result.to_h).to eq({ "blue" => m })
    expect(result.stop?).to be_truthy

    text = result.render
    expect(text).to match(/existing new/)
  end

  it "treats empty/blank string as no value" do
    template = a_template_with_params({ "existing" => "", "new" => "  " })
    description = a_description_with_params({ "existing" => " " })
    description.data["Stacks"][0]["Parameters"] << { "ParameterKey" => "new" }

    checker = make_checker({ "blue" => [ template, description ] })
    result = checker.check

    # Both pre-existing parameters, and new ones
    expect(result.to_h["blue"][:no_value_parameters]).to eq(%w[ existing new ])
    expect(result.stop?).to be_truthy

    text = result.render
    expect(text).to match(/existing new/)
  end

end
