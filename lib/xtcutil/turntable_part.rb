module Xtcutil
  class TurntablePart < Xtcutil::AbstractPart
    def lines
      return @lines if defined? @lines
      center = Vector[*@h[:pos]]
      radius = @h[:radius]
      ary = []
      @h[:segs].each {|seg|
        case seg[:type]
        when 'T'
          a = seg[:angle] * DEG_TO_RAD
          vec = Vector[Math.sin(a), Math.cos(a)]
          pos0 = center + vec * radius
          pos1 = center - vec * radius
          line = StraightLine.new(self, pos0, pos1)
          node_other_end = line.get_node(1)
          node_other_end.add_comment("T#{self.index}TP_A#{"%.3f" % seg[:angle]}")
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
        state = "a#{a += 1}"
        ary << [state, [[l]]]
      }
      return @paths_ary = ary
    end

    def each_state_paths
      paths_ary.each {|state, paths|
        yield state, paths, true, false
      }
    end

  end
end
