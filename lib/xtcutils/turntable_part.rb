class TurntablePart
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
    ary = []
    @h[:segs].each {|seg|
      case seg[:type]
      when 'T'
        a = seg[:angle] * DEG_TO_RAD
        s = Math.sin(a)
        c = Math.cos(a)
        x0 = cx + radius * s
        y0 = cy + radius * c
        x1 = cx - radius * s
        y1 = cy - radius * c
        ary << StraightLine.new(x0, y0, x1, y1)
      end
    }
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end
end
