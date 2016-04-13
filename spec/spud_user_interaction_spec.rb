require 'spud'

describe Spud::UserInteraction do

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
end
