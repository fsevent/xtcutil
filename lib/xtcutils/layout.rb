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

  def parts_ary
    return @parts_ary if defined? @parts_ary
    ary = []
    @parsed.each {|h|
      case h[:type]
      when 'straight'
        obj = StraightPart.new(self, h)
      when 'joint'
        obj = JointPart.new(self, h)
      when 'curve'
        obj = CurvePart.new(self, h)
      when 'turnout'
        obj = TurnoutPart.new(self, h)
      when 'turntable'
        obj = TurntablePart.new(self, h)
      else
        next
      end
      ary[obj.index] = obj
    }
    return @parts_ary = ary
  end

  def each_part(&b)
    parts_ary.each {|obj|
      next if obj.nil?
      yield obj
    }
  end
end
