module StackFetcher

  class StackTypes

    def self.list
      Dir.glob("src/*").reject {|s| s.start_with? "."}.sort
    end

  end

end
