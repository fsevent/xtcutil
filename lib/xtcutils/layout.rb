class Layout
  def initialize(parsed)
    @parsed = parsed
  end
  attr_reader :parsed

  def roomsize
    return @roomsize if defined? @roomsize
    @parsed.each {|h|
      if h[:type] == 'roomsize'
        return @roomsize = [h[:x], h[:y]]
      end
    }
    return @roomsize = nil
  end
end
