class CurveLine < AbstractLine
  def initialize(part, cx, cy, radius, a0, a1)
    raise "curveline constraint violation: #{a0} > #{a1} (should be a0 <= a1)" if a0 > a1
    pos0 = [
      cx + radius * Math.cos(a0),
      cy + radius * Math.sin(a0)
    ].freeze
    pos1 = [
      cx + radius * Math.cos(a1),
      cy + radius * Math.sin(a1)
    ].freeze
    dir_angle0 = (a0 - Math::PI/2) % (2 * Math::PI)
    dir_angle1 = (a1 + Math::PI/2) % (2 * Math::PI)
    super part, pos0, pos1, dir_angle0, dir_angle1
    @cx = cx
    @cy = cy
    @radius = radius
    @a0 = a0
    @a1 = a1
  end
  attr_reader :cx, :cy, :radius, :a0, :a1

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
