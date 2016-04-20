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
      @data = @clean_data = nil
      @dirty = false
    end

    def loaded?
      not @data.nil?
    end

    def dirty?
      @dirty or @data != @clean_data
    end

    def data
      if @data.nil?
        content = IO.read path
        @clean_data = JSON.parse content
        @data = Spud.deep_copy @clean_data
        @dirty = (content != format)
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
      @dirty = false
    end

    private

    def read_file
      JSON.parse(IO.read path)
    end

    def write_file
      @data or raise "No data to write"
      tmp = path + ".tmp"
      IO.write(tmp, format)
      File.rename tmp, path
    end

    def format
      JSON.pretty_generate(@data)+"\n"
    end

  end

end
