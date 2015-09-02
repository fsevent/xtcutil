class StraightLine < AbstractLine
  def initialize(part, x0, y0, x1, y1)
    pos0 = [x0, y0].freeze
    pos1 = [x1, y1].freeze
    dir_angle0 = Math.atan2(y0-y1, x0-x1) % (2 * Math::PI)
    dir_angle1 = (dir_angle0 + Math::PI) % (2 * Math::PI)
    super part, pos0, pos1, dir_angle0, dir_angle1
    @x0 = x0
    @y0 = y0
    @x1 = x1
    @y1 = y1
  end
  attr_reader :x0, :y0, :x1, :y1

  def distance
    hypot_pos(pos0, pos1)
  end

  def vector(tipindex)
    raise "unexpected pos index: #{i}" if i != 0 && i != 1
    return @vector if defined? @vector
    d = distance
    return @vector = [(@x1-@x0)/d, (@y1-@y0)/d]
  end

end
