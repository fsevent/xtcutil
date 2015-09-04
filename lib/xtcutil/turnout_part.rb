module Xtcutil
  class TurnoutPart < Xtcutil::AbstractPart
    include MathUtil

    def lines
      return @lines if defined? @lines
      mat = Matrix.I(3)
      orig = Vector[*@h[:orig]]
      angle = @h[:angle] * DEG_TO_RAD
      mat = mat * matrix_translate(orig)
      mat = mat * matrix_rotate(-angle)
      ary = []
      @h[:segs].each {|seg|
        case seg[:type]
        when 'S'
          pos0 = Vector[*seg[:pos0]]
          pos1 = Vector[*seg[:pos1]]
          pos0 = affine_transform(mat, pos0)
          pos1 = affine_transform(mat, pos1)
          ary << StraightLine.new(self, pos0, pos1)
        when 'C'
          center = Vector[*seg[:center]]
          radius = seg[:radius]
          if 0 < radius
            a0 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
            a1 = (90-seg[:a0]) * DEG_TO_RAD
            center = affine_transform(mat, center)
            a1 = rotate_angle(mat, a1)
            a0 = rotate_angle(mat, a0)
          else
            a0 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
            a1 = (90-seg[:a0]) * DEG_TO_RAD
            center = affine_transform(mat, center)
            radius = -radius
            a0 = rotate_angle(mat, a0)
            a1 = rotate_angle(mat, a1)
          end
          ary << CurveLine.new(self, center, radius, a0, a1)
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
        yield name, paths, true, true
      }
    end


  end
end
