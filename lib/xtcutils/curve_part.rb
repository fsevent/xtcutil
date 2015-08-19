class CurvePart
  def initialize(layout, h)
    @layout = layout
    @h = h
  end

  def index
    @h[:index].to_int
  end

  def lines
    return @lines if defined? @lines
    cx, cy = @h[:pos]
    radius = @h[:radius]
    a0 = @h[:segs][1][:angle]
    a1 = @h[:segs][0][:angle]
    if a0 == 90 && a1 == 270
      a0 = 0.0
      a1 = 2*Math::PI
    else
      a0 = (180-a0) * DEG_TO_RAD
      a1 = (-a1) * DEG_TO_RAD
    end
    ary = [CurveLine.new(cx, cy, radius, a0, a1)]
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end
end
