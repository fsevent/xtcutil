class CurveLine < AbstractLine
  def initialize(part, center, radius, a0, a1)
    raise "curveline constraint violation: #{a0} > #{a1} (should be a0 <= a1)" if a0 > a1
    pos0 = Vector[
      center[0] + radius * Math.cos(a0),
      center[1] + radius * Math.sin(a0)
    ].freeze
    pos1 = Vector[
      center[0] + radius * Math.cos(a1),
      center[1] + radius * Math.sin(a1)
    ].freeze
    dir_angle0 = (a0 - Math::PI/2) % (2 * Math::PI)
    dir_angle1 = (a1 + Math::PI/2) % (2 * Math::PI)
    super part, pos0, pos1, dir_angle0, dir_angle1
    @center = center
    @radius = radius
    @a0 = a0
    @a1 = a1
  end
  attr_reader :center, :radius, :a0, :a1

  def distance
    @radius * (@a1 - @a0)
  end

  def vector(tipindex)
    raise "unexpected pos index: #{i}" if i != 0 && i != 1
    return @vectors[tipindex] if defined? @vectors
    @vectors = [
      [
        -Math.sin(@a0),
        Math.cos(@a0),
      ],
      [
        -Math.sin(@a1),
        Math.cos(@a1),
      ],
    ]
    return @vectors[tipindex]
  end

end
