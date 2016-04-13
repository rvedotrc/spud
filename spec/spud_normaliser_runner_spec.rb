require 'spud'

describe Spud::NormaliserRunner do

  it "should normalise each file" do

    context = double("context")
    expect(context).to receive(:stack_types).and_return(%w[ blue green ])

    normaliser = double("normaliser")
    expect(Spud::FileNormaliser).to receive(:new).and_return(normaliser)

    tmp_files = double("tmp files")

    %w[ blue green ].each do |stack_type|
      %i[ current_template current_description generated_template ].each do |sym|

        a_tmp_file = double("a tmp file")
        expect(tmp_files).to receive(:get).with(sym, stack_type).and_return(a_tmp_file)
        expect(normaliser).to receive(:normalise_file).with(a_tmp_file)

      end
    end

    Spud::NormaliserRunner.new(context, tmp_files).normalise_all

  end

end

describe Spud::FileNormaliser do

  def a_template
    {
      "AWSTemplateFormatVersion" => "2010-09-09",
      "Resources" => {
        "MyTopic" => {
          "Type" => "AWS::SNS::Topic",
        },
      },
    }
  end

  def a_snake_case_description
    {
      "stacks" => [
        {
          "stack_name" => "MyStack",
          "notification_arns" => [ "foo" ],
          "parameters" => [ { "parameter_key" => "k", "parameter_value" => "v" } ],
        }
      ],
    }
  end

  def a_title_case_description
    {"Stacks"=>[{
      "Capabilities"=>[],
      "NotificationARNs"=>["foo"],
      "Outputs"=>[],
      "Parameters"=>[{"ParameterKey"=>"k", "ParameterValue"=>"v"}],
      "StackName"=>"MyStack",
      "Tags"=>[],
    }]}
  end

  def run(data_in)
    data_out = nil
    flushed_data = nil

    tmp_file = double("a tmp file")
    expect(tmp_file).to receive(:data).and_return(data_in)
    expect(tmp_file).to receive(:data=) {|x| data_out = x}
    expect(tmp_file).to receive(:flush!) { flushed_data = data_out }
    Spud::FileNormaliser.new.normalise_file(tmp_file)

    expect(flushed_data).to eq(data_out)
    flushed_data
  end

  def it_normalises(data_in)
    i1 = {"some" => "thing", "another" => "thing"}

    n = double("stack normaliser")
    expect(Spud::StackNormaliser).to receive(:new).and_return(n)
    expect(n).to receive(:normalise_stack).with(data_in).and_return(i1)
    
    data_out = run(data_in)

    expect(data_out).to eq(i1)
    expect(data_out.keys).to eq(%w[ another some ])
  end

  it "reads, assigns and flushes the data" do
    run a_template
  end

  it "converts description snake_case to TitleCase" do
    data_in = a_snake_case_description
    data_out = run(data_in)

    expect(data_out["Stacks"][0]["StackName"]).to eq("MyStack")
    expect(data_out["Stacks"][0]["NotificationARNs"]).to eq([ "foo" ])
    expect(data_out["Stacks"][0]["Parameters"][0]).to eq({ "ParameterKey" => "k", "ParameterValue" => "v" })
  end

  it "leaves TitleCase description alone" do
    data_in = a_title_case_description
    data_out = run(data_in)

    expect(data_out["Stacks"][0]["StackName"]).to eq("MyStack")
    expect(data_out["Stacks"][0]["NotificationARNs"]).to eq([ "foo" ])
    expect(data_out["Stacks"][0]["Parameters"][0]).to eq({ "ParameterKey" => "k", "ParameterValue" => "v" })
  end

  it "leaves the case of templates alone" do
    data_in = a_template
    data_out = run(data_in)

    expect(data_out.keys.sort).to eq(%w[ AWSTemplateFormatVersion Resources ])
  end

  it "normalises templates" do
    it_normalises a_template
  end

  it "normalises descriptions" do
    it_normalises a_title_case_description
  end

end
