module Xtcutil
  class CurvePart < Xtcutil::AbstractPart
    def circle?
      a0 = @h[:segs][0][:angle]
      a1 = @h[:segs][1][:angle]
      a0 == 270.0 && a1 == 90.0
    end

    def lines
      return @lines if defined? @lines
      center = Vector[*@h[:pos]]
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
      while a0 > a1
        a1 += 2*Math::PI
      end
      ary = [CurveLine.new(self, center, radius, a0, a1)]
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
end
