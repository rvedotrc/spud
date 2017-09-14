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
    expect(Readline).to receive(:readline).with("QQQ: ", true) { "42" }

    answer = Spud::UserInteraction.get_mandatory_text(
      question: "QQQ",
    )
    expect(answer).to eq("42")
  end

  it "should fail when readline returns nil" do
    # Readline.readline returns nil when stdin is /dev/null.
    expect(Readline).to receive(:readline).with("QQQ: ", true) { nil }
    expect {Spud::UserInteraction.get_mandatory_text(question: "QQQ")}.to raise_exception(Spud::UserInteractionError, /.*EOF.*/i)
  end

  it "should keep asking until a non-blank answer is given" do
    expect(Readline).to receive(:readline).with("QQQ: ", true).and_return("", "  ", " 42 ", "x").exactly(3)

    answer = Spud::UserInteraction.get_mandatory_text(
      question: "QQQ",
    )
    expect(answer).to eq(" 42 ")
  end

  it "should prefill history" do
    expect(Readline::HISTORY).to receive(:push).with("MyDefault")
    expect(Readline).to receive(:readline).with("QQQ (press up for default): ", true) { "42" }

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

  it "should fail when confirm_default_no receives EOF" do
    expect(Readline).to receive(:readline).with("QQQ? [y/N]: ") { nil }
    expect {Spud::UserInteraction.confirm_default_no(
            question: "QQQ?")
    }.to raise_exception(Spud::UserInteractionError, /.*EOF.*/i)
  end

  it "should fail when confirm_default_yes receives EOF" do
    expect(Readline).to receive(:readline).with("QQQ? [Y/n]: ") { nil }
    expect {Spud::UserInteraction.confirm_default_yes(
            question: "QQQ?")
    }.to raise_exception(Spud::UserInteractionError, /.*EOF.*/i)
  end

  it "does info_press_return" do
    m = "This is important"
    expect(Readline).to receive(:readline).with("#{m} [press return]: ")
    Spud::UserInteraction.info_press_return(m)
  end

end
