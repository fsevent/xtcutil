class JointPart < AbstractPart
  def lines
    # track transition curve (easement) is replaced by a straight line.
    return @lines if defined? @lines
    x0, y0 = @h[:segs][0][:pos]
    x1, y1 = @h[:segs][1][:pos]
    ary = [StraightLine.new(self, x0, y0, x1, y1)]
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end

  def paths_ary
    return @paths_ary if defined? @paths_ary
    return @paths_ary = [[lines]]
  end

  def each_state_paths
    yield nil, paths_ary[0], true, true
  end

end
