class StraightPart
  def initialize(layout, h)
    @layout = layout
    @h = h
  end

  def index
    @h[:index].to_int
  end

  def lines
    return @lines if defined? @lines
    x0, y0 = @h[:segs][0][:pos]
    x1, y1 = @h[:segs][1][:pos]
    ary = [StraightLine.new(x0, y0, x1, y1)]
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end
end
