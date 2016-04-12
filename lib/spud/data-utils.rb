module Spud

  def self.deep_copy(d)
    if d.kind_of? Array
      d.map {|v| deep_copy v}.to_a
    elsif d.kind_of? Hash
      d.entries.each_with_object({}) {|pair, h| h[deep_copy pair.first] = deep_copy pair.last}
    else
      d
    end
  end

end
