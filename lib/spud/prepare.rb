require 'shellwords'

module Spud

  class Prepare

    attr_reader :context, :tmp_files

    def initialize(context)
      @context = context
    end

    def run
      # By the time we get here, global options and the verb "prepare" have
      # already been consumed from argv.

      # move tmp_files to context?
      # have each tmp file be (name+content) object with methods to save, etc

      @context.stack_types = StackTypes.new(context).list

      if @context.stack_types.empty?
        puts "No stack types defined - nothing to do"
        return
      end

      puts "Determining stack names"
      @context.stack_names = StackFinder.new(context).get_names
      @tmp_files = TmpFiles.new(@context)
      @tmp_files.clean!
      puts ""

      puts "Retrieving existing stacks"
      Puller.new(context, tmp_files).get_all
      puts ""

      puts "Generating target stacks"
      Generator.new(context, tmp_files).generate_all
      puts ""

      puts "Normalising"
      NormaliserRunner.new(context, tmp_files).normalise_all
      tmp_files.copy_current_to_next

      comparison = StackComparer.new(context, tmp_files).compare
      puts ""
      comparison.print
      puts ""

      show_instructions

      context.save
    end

    def show_instructions
      puts <<EOF
You should now edit the "next" files to suit, for example using the following
commands:

EOF

      context.stack_types.each do |t|
        puts <<EOF
  vimdiff #{tmp_files.current_generated_next_shell(t)} ; vim #{Shellwords.shellescape tmp_files.next_description(t)}
EOF
      end

      puts <<EOF

then run spud "apply".

EOF
    end

  end

end
