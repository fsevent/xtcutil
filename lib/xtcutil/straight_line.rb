module Xtcutil
  class StraightLine < Xtcutil::AbstractLine
    def initialize(part, pos0, pos1)
      vec = pos0-pos1
      dir_angle0 = Math.atan2(vec[1], vec[0]) % (2 * Math::PI)
      dir_angle1 = (dir_angle0 + Math::PI) % (2 * Math::PI)
      super part, pos0, pos1, dir_angle0, dir_angle1
      @pos0 = pos0
      @pos1 = pos1
    end
    attr_reader :pos0, :pos1

    def distance
      (pos0 - pos1).r
    end

    def radius
      Float::INFINITY
    end

    def vector(tipindex)
      raise "unexpected pos index: #{i}" if i != 0 && i != 1
      return @vector if defined? @vector
      d = distance
      return @vector = [(@x1-@x0)/d, (@y1-@y0)/d]
    end

  end
end
