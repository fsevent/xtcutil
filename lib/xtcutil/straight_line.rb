class StraightLine < AbstractLine
  def initialize(part, x0, y0, x1, y1)
    super part
    @x0 = x0
    @y0 = y0
    @x1 = x1
    @y1 = y1
  end
  attr_reader :x0, :y0, :x1, :y1

  def pos0
    return @pos0 if defined? @pos0
    return @pos0 = [@x0, @y0].freeze
  end

  def pos1
    return @pos1 if defined? @pos1
    return @pos1 = [@x1, @y1].freeze
  end

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
