require 'readline'

module Spud

  class UserInteraction

    def self.get_mandatory_text(opts)
      # :question (mandatory)
      # :prefill (may be nil)
      # return: text (single line, chomped)

      prompt = opts[:question]

      if opts[:prefill]
        Readline::HISTORY.push opts[:prefill]
        prompt += " (press up for default)"
      end

      answer = nil

      while true
        answer = Readline.readline "#{prompt}: "
        break if answer.match /\S/
      end

      answer
    end

    def self.confirm_default_no(opts)
      prompt = opts[:question] + " [y/N]"
      answer = Readline.readline "#{prompt}: "
      answer = "n" unless answer.match /\S/
      answer.match /^\s*y/i
    end

    def self.confirm_default_yes(opts)
      prompt = opts[:question] + " [Y/n]"
      answer = Readline.readline "#{prompt}: "
      answer = "y" unless answer.match /\S/
      answer.match /^\s*y/i
    end

  end

end
