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

        a_tmp_file = double("a tmp file for #{stack_type} #{sym}")
        expect(tmp_files).to receive(:get).with(sym, stack_type).and_return(a_tmp_file)
        expect(normaliser).to receive(:normalise_file).with(a_tmp_file)

      end
    end

    Spud::NormaliserRunner.new(context, tmp_files).normalise_all

  end

end
