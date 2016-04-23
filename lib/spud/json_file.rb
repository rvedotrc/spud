require 'digest/sha1'
require 'fileutils'
require 'json'

module Spud

  class JsonFile

    attr_reader :path

    def initialize(path)
      @path = path
      discard!
    end

    def delete!
      FileUtils.rm_f path
      discard!
    end

    def discard!
      @data = @clean_data = @clean_content_digest = nil
    end

    def loaded?
      not @data.nil?
    end

    def dirty?
      return false unless @data
      @data != @clean_data or digest_of(format) != @clean_content_digest
    end

    def data
      if @data.nil?
        content = IO.read path
        @clean_data = JSON.parse content
        @clean_content_digest = digest_of(content)
        @data = Spud.deep_copy @clean_data
      end
      @data
    end

    def data=(d)
      @data = Spud.deep_copy d
    end

    def flush
      flush! if dirty?
    end

    def flush!
      @data or raise "No data to write"
      write_file
      @clean_data = Spud.deep_copy @data
    end

    private

    def read_file
      JSON.parse(IO.read path)
    end

    def write_file
      @data or raise "No data to write"
      content = format

      tmp = path + ".tmp"
      IO.write tmp, content
      File.rename tmp, path

      @clean_content_digest = digest_of(content)
    end

    def format
      JSON.pretty_generate(@data)+"\n"
    end

    def digest_of(s)
      Digest::SHA1.hexdigest s
    end

  end

end
