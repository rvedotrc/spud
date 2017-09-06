module Spud

  class StackTypes

    attr_reader :context

    def initialize(context)
      @context = context
    end

    def list
      Dir.new('src').entries
        .reject {|s| s.start_with? '.'}
        .reject {|s| (@context.config.has_key? s and @context.config[s]['skip'])}
        .keep_if {|s| File.directory?("src/#{s}")}
        .sort
    end

  end

end
