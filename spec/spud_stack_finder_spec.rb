require 'spud'

RSpec::Matchers.define :name_prompt_for_type do |type, prefill|
  match do |actual|
    (
      actual[:question] == "Enter name for the #{type.inspect} stack" \
      and \
      actual[:prefill] == prefill
    )
  end
end

describe Spud::StackFinder do

  before do
    @stacks = []
    @context = double 'context'
    allow(@context).to receive(:stacks).and_return(@stacks)

    @stack_name_suggester = double 'stack_name_suggester'
    extensions = double 'extensions'
    allow(extensions).to receive(:stack_name_suggester).and_return(@stack_name_suggester)
    allow(@context).to receive(:extensions).and_return(extensions)
  end

  def expect_name_suggest(type, response)
    expect(@stack_name_suggester).to receive(:suggest_name).with(@context, type).and_return(response)
  end

  def do_not_expect_name_suggest(type)
    expect(@stack_name_suggester).not_to receive(:suggest_name).with(@context, type)
  end

  def expect_name_prompt(type, prefill, response)
    expect(Spud::UserInteraction).to receive(:get_mandatory_text).with(name_prompt_for_type(type, prefill)).and_return(response).ordered
  end

  def do_not_expect_name_prompt(type)
    expect(Spud::UserInteraction).not_to receive(:get_mandatory_text).with(name_prompt_for_type(type))
  end

  it "gets a stack name" do
    @stacks << Spud::Stack.new(nil, 'type1', 'myacc', 'my-region-1', false)

    expect_name_suggest 'type1', 'Suggestion1'
    expect_name_prompt 'type1', 'Suggestion1', 'Prompted1'

    r = Spud::StackFinder.new(@context).get_names

    expect(r).to eq(@stacks)
    expect(@stacks.map &:name).to eq(%w[ Prompted1 ])
  end

  it "does not ask for name if it already has a name" do
    @stacks << Spud::Stack.new('AlreadyGotAName', 'type1', 'myacc', 'my-region-1', false)

    do_not_expect_name_suggest 'type1'
    do_not_expect_name_prompt 'type1'

    r = Spud::StackFinder.new(@context).get_names

    expect(r).to eq(@stacks)
    expect(@stacks.map &:name).to eq(%w[ AlreadyGotAName ])
  end

  it "processes stacks in the right order" do
    @stacks << Spud::Stack.new(nil, 'type-foo', 'myacc', 'my-region-1', false)
    @stacks << Spud::Stack.new('X', 'type-bar', 'myacc', 'my-region-1', false)
    @stacks << Spud::Stack.new(nil, 'type-baz', 'myacc', 'my-region-1', false)

    expect_name_suggest 'type-foo', 'SuggestionFoo'
    expect_name_suggest 'type-baz', 'SuggestionBaz'

    # We care about the order of the prompts (but not the suggests)
    # i.e. in the same order as context.stacks
    expect_name_prompt 'type-foo', 'SuggestionFoo', 'PromptedFoo'
    expect_name_prompt 'type-baz', 'SuggestionBaz', 'PromptedBaz'

    Spud::StackFinder.new(@context).get_names
  end

  it "deals with no suggestion" do
    # TODO: if the suggester returns blank / nil
  end

  it "warns about bad suggestions" do
    # TODO: if the suggester returns something which isn't a valid stack name,
    # a warning should be shown
  end

  it "loops until a valid name is entered" do
    # TODO: if the user enters an invalid stack name, loop
  end

end
