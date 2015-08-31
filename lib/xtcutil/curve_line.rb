class CurveLine < AbstractLine
  def initialize(part, cx, cy, radius, a0, a1)
    raise "curveline constraint violation: #{a0} > #{a1} (should be a0 <= a1)" if a0 > a1
    super part
    @cx = cx
    @cy = cy
    @radius = radius
    @a0 = a0
    @a1 = a1
  end
  attr_reader :cx, :cy, :radius, :a0, :a1

  def pos0
    return @pos0 if defined? @pos0
    @pos0 = [
      @cx + @radius * Math.cos(@a0),
      @cy + @radius * Math.sin(@a0)
    ]
    return @pos0
  end

  def pos1
    return @pos1 if defined? @pos1
    @pos1 = [
      @cx + @radius * Math.cos(@a1),
      @cy + @radius * Math.sin(@a1)
    ]
    return @pos1
  end

  def distance
    @radius * (@a1 - @a0)
  end

  def vector(posindex)
    raise "unexpected pos index: #{i}" if i != 0 && i != 1
    return @vectors[posindex] if defined? @vectors
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
    return @vectors[posindex]
  end

end
