require 'fileutils'

module Spud

  module Ext

    class DefaultGenerator

      def generate(context, stacks)
        env = context.argv.last || "default"

        # Just a simple copy
        stacks.each do |stack_type, details|
          src = "src/#{stack_type}/template.#{env}.json"
          dst = details[:template]
          FileUtils.cp src, dst
        end
      end

    end

  end

end

# vi: ts=2 sts=2 sw=2 et :
