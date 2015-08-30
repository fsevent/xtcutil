class TurntablePart < AbstractPart
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
        line = StraightLine.new(self, x0, y0, x1, y1)
        line.set_line_name("T#{self.index}A#{"%.3f" % seg[:angle]}")
        node_other_end = Node.new
        node_other_end.add_comment("T#{self.index}TP")
        line.set_node(1, node_other_end)
        ary << line
      end
    }
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end

  def paths_ary
    return @paths_ary if defined? @paths_ary
    ary = []
    a = 0
    lines.each {|l|
      name = "a#{a += 1}"
      ary << [name, [[l]]]
    }
    return @paths_ary = ary
  end

  def each_state_paths
    paths_ary.each {|name, paths|
      yield name, paths
    }
  end

end
