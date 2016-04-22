require 'spud'

describe Spud::UserInteraction do

  def test_confirm(method, suffix, user_input, expected_result)
    expect(Readline).to receive(:readline).with("QQQ? #{suffix}: ") { user_input }

    answer = Spud::UserInteraction.send(
      method,
      question: "QQQ?",
    )
    expect(answer).to be_truthy if expected_result
    expect(answer).to be_falsy if !expected_result
  end

  it "should get answer from readline" do
    expect(Readline).to receive(:readline).with("QQQ: ") { "42" }

    answer = Spud::UserInteraction.get_mandatory_text(
      question: "QQQ",
    )
    expect(answer).to eq("42")
  end

  it "should keep asking until a non-blank answer is given" do
    expect(Readline).to receive(:readline).with("QQQ: ").and_return("", "  ", " 42 ", "x").exactly(3)

    answer = Spud::UserInteraction.get_mandatory_text(
      question: "QQQ",
    )
    expect(answer).to eq(" 42 ")
  end

  it "should prefill history" do
    expect(Readline::HISTORY).to receive(:push).with("MyDefault")
    expect(Readline).to receive(:readline).with("QQQ (press up for default): ") { "42" }

    answer = Spud::UserInteraction.get_mandatory_text(
      question: "QQQ",
      prefill: "MyDefault",
    )
    expect(answer).to eq("42")
  end

  it "confirm_default_yes y" do
    test_confirm :confirm_default_yes, "[Y/n]", "y", true
  end

  it "confirm_default_yes return" do
    test_confirm :confirm_default_yes, "[Y/n]", "", true
  end

  it "confirm_default_yes n" do
    test_confirm :confirm_default_yes, "[Y/n]", "n", false
  end

  it "confirm_default_yes other" do
    test_confirm :confirm_default_yes, "[Y/n]", "foo", false
  end

  it "confirm_default_no y" do
    test_confirm :confirm_default_no, "[y/N]", "y", true
  end

  it "confirm_default_no return" do
    test_confirm :confirm_default_no, "[y/N]", "", false
  end

  it "confirm_default_no n" do
    test_confirm :confirm_default_no, "[y/N]", "n", false
  end

  it "confirm_default_no other" do
    test_confirm :confirm_default_no, "[y/N]", "foo", false
  end

  it "does info_press_return" do
    m = "This is important"
    expect(Readline).to receive(:readline).with("#{m} [press return]: ")
    Spud::UserInteraction.info_press_return(m)
  end

end
