require 'matrix'

DEG_TO_RAD = Math::PI / 180

def matrix_rotate(rad)
  c = Math.cos(rad)
  s = Math.sin(rad)
  Matrix[
    [c, -s, 0.0],
    [s, c, 0.0],
    [0.0, 0.0, 1]
  ]
end

def matrix_translate(x, y)
  Matrix[
    [1.0, 0.0, x],
    [0.0, 1.0, y],
    [0.0, 0.0, 1.0]
  ]
end

def affine_transform(mat, x, y)
  x, y, _ = (mat * Vector[x, y, 1.0]).to_a
  return x, y
end

def rotate_angle(mat, rad)
  c = mat[0,0]
  s = mat[1,0]
  rad + Math.atan2(s, c)
end

class StraightLine
  def initialize(x0, y0, x1, y1)
    @x0 = x0
    @y0 = y0
    @x1 = x1
    @y1 = y1
  end
  attr_reader :x0, :y0, :x1, :y1
end

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

class StraightPart
  def initialize(layout, h)
    @layout = layout
    @h = h
  end

  def index
    @h[:index].to_int
  end

  def lines
    return @lines if defined? @lines
    x0, y0 = @h[:segs][0][:pos]
    x1, y1 = @h[:segs][1][:pos]
    ary = [StraightLine.new(x0, y0, x1, y1)]
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end
end

class JointPart
  def initialize(layout, h)
    @layout = layout
    @h = h
  end

  def index
    @h[:index].to_int
  end

  def lines
    # track transition curve (easement) is replaced by a straight line.
    return @lines if defined? @lines
    x0, y0 = @h[:segs][0][:pos]
    x1, y1 = @h[:segs][1][:pos]
    ary = [StraightLine.new(x0, y0, x1, y1)]
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end

end

class CurvePart
  def initialize(layout, h)
    @layout = layout
    @h = h
  end

  def index
    @h[:index].to_int
  end

  def lines
    return @lines if defined? @lines
    cx, cy = @h[:pos]
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
    ary = [CurveLine.new(cx, cy, radius, a0, a1)]
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end
end

class TurnoutPart
  def initialize(layout, h)
    @layout = layout
    @h = h
  end

  def index
    @h[:index].to_int
  end

  def lines
    return @lines if defined? @lines
    mat = Matrix.I(3)
    ox, oy = @h[:orig]
    angle = @h[:angle]
    mat = mat * matrix_translate(ox, oy)
    mat = mat * matrix_rotate(-angle * DEG_TO_RAD)
    ary = []
    @h[:segs].each {|seg|
      case seg[:type]
      when 'S'
        x0, y0 = seg[:pos0]
        x1, y1 = seg[:pos1]
        x0, y0 = affine_transform(mat, x0, y0)
        x1, y1 = affine_transform(mat, x1, y1)
        ary << StraightLine.new(x0, y0, x1, y1)
      when 'C'
        cx, cy = seg[:center]
        radius = seg[:radius]
        if 0 < radius
          a0 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
          a1 = (90-seg[:a0]) * DEG_TO_RAD
          cx, cy = affine_transform(mat, cx, cy)
          a1 = rotate_angle(mat, a1)
          a0 = rotate_angle(mat, a0)
        else
          a0 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
          a1 = (90-seg[:a0]) * DEG_TO_RAD
          cx, cy = affine_transform(mat, cx, cy)
          radius = -radius
          a0 = rotate_angle(mat, a0)
          a1 = rotate_angle(mat, a1)
        end
        ary << CurveLine.new(cx, cy, radius, a0, a1)
      end
    }
    return @lines = ary
  end

  def each_track(&b)
    lines.each(&b)
  end
end

class Layout
  def initialize(parsed)
    @parsed = parsed
  end
  attr_reader :parsed

  def roomsize
    return @roomsize if defined? @roomsize
    @parsed.each {|h|
      if h[:type] == 'roomsize'
        return @roomsize = [h[:x], h[:y]]
      end
    }
    return @roomsize = nil
  end

  def parts_ary
    return @parts_ary if defined? @parts_ary
    ary = []
    @parsed.each {|h|
      case h[:type]
      when 'straight'
        obj = StraightPart.new(self, h)
      when 'joint'
        obj = JointPart.new(self, h)
      when 'curve'
        obj = CurvePart.new(self, h)
      when 'turnout'
        obj = TurnoutPart.new(self, h)
      #when 'turntable'
        #obj = TurntablePart.new(self, h)
      else
        next
      end
      ary[obj.index] = obj
    }
    return @parts_ary = ary
  end

  def each_part(&b)
    parts_ary.each {|obj|
      next if obj.nil?
      yield obj
    }
  end
end
