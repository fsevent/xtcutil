module Xtcutil
  class StraightPart < Xtcutil::AbstractPart
    def lines
      return @lines if defined? @lines
      @pos0 = Vector[*@h[:segs][0][:pos]]
      @pos1 = Vector[*@h[:segs][1][:pos]]
      ary = [StraightLine.new(self, @pos0, @pos1)]
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
