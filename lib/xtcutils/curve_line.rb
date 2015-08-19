class CurveLine
  def initialize(cx, cy, radius, a0, a1)
    @cx = cx
    @cy = cy
    @radius = radius
    @a0 = a0
    @a1 = a1
  end
  attr_reader :cx, :cy, :radius, :a0, :a1
end
