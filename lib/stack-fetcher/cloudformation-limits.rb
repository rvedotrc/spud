module StackFetcher

  class CloudformationLimits

    def self.valid_stack_name?(name)
      name.match /\A[A-Za-z0-9][A-Za-z0-9-]{0,127}\z/
    end

  end

end
