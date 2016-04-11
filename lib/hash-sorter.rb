class HashSorter

  def sort_hash(d)
    if d.kind_of? Hash
      h = {}
      d.keys.sort.each {|k| h[k] = sort_hash(d[k]) }
      return h
    elsif d.kind_of? Array
      return d.map {|e| sort_hash(e) }
    else
      return d
    end
  end

end
