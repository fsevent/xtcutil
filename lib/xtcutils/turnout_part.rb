class TurnoutPart < AbstractPart
  def lines
    return @lines if defined? @lines
    mat = Matrix.I(3)
    ox, oy = @h[:orig]
    angle = @h[:angle]
    mat = mat * matrix_translate(ox, oy)
    mat = mat * matrix_rotate(-angle * DEG_TO_RAD)
    ary = []
    @h[:segs].each {|seg|
      case seg[:type]
      when 'S'
        x0, y0 = seg[:pos0]
        x1, y1 = seg[:pos1]
        x0, y0 = affine_transform(mat, x0, y0)
        x1, y1 = affine_transform(mat, x1, y1)
        ary << StraightLine.new(self, x0, y0, x1, y1)
      when 'C'
        cx, cy = seg[:center]
        radius = seg[:radius]
        if 0 < radius
          a0 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
          a1 = (90-seg[:a0]) * DEG_TO_RAD
          cx, cy = affine_transform(mat, cx, cy)
          a1 = rotate_angle(mat, a1)
          a0 = rotate_angle(mat, a0)
        else
          a0 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
          a1 = (90-seg[:a0]) * DEG_TO_RAD
          cx, cy = affine_transform(mat, cx, cy)
          radius = -radius
          a0 = rotate_angle(mat, a0)
          a1 = rotate_angle(mat, a1)
        end
        ary << CurveLine.new(self, cx, cy, radius, a0, a1)
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
    each_seg {|seg|
      next if seg[:type] != 'P'
      name = seg[:name]
      paths = seg[:paths].map {|path|
        path.map {|i|
          lines[i-1]
        }
      }
      ary << [name, paths]
    }
    return @paths_ary = ary
  end

  def each_state_paths
    paths_ary.each {|name, paths|
      yield name, paths
    }
  end


end
