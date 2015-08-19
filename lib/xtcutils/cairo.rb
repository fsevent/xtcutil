require 'matrix'
require 'cairo'

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

def cairo_draw_layout layout, ctx
  ctx.set_line_width 1
  layout.parsed.each {|h|
    case h[:type]
    when 'straight'
      ctx.set_source_rgb(0, 0, 0)
      x1, y1 = h[:segs][0][:pos]
      x2, y2 = h[:segs][1][:pos]
      ctx.move_to(x1, y1)
      ctx.line_to(x2, y2)
      ctx.stroke
    when 'joint'
      # track transition curve (easement) is replaced by straight line.
      ctx.set_source_rgb(0, 0, 0)
      x1, y1 = h[:segs][0][:pos]
      x2, y2 = h[:segs][1][:pos]
      ctx.move_to(x1, y1)
      ctx.line_to(x2, y2)
      ctx.stroke
    when 'curve'
      ctx.set_source_rgb(0, 0, 0)
      cx, cy = h[:pos]
      radius = h[:radius]
      a0 = h[:segs][0][:angle]
      a1 = h[:segs][1][:angle]
      if a0 == 270 && a1 == 90
        a0 = 2*Math::PI
        a1 = 0.0
      else
        a0 = (-a0) * DEG_TO_RAD
        a1 = (180-a1) * DEG_TO_RAD
      end
      ctx.arc(cx, cy, radius, a1, a0)
      ctx.stroke
    when 'turnout'
      mat = Matrix.I(3)
      ox, oy = h[:orig]
      angle = h[:angle]
      mat = mat * matrix_translate(ox, oy)
      mat = mat * matrix_rotate(-angle * DEG_TO_RAD)
      h[:segs].each {|seg|
        case seg[:type]
        when 'S'
          ctx.set_source_rgb(0, 0, 0)
          x0, y0 = seg[:pos0]
          x1, y1 = seg[:pos1]
          x0, y0 = affine_transform(mat, x0, y0)
          x1, y1 = affine_transform(mat, x1, y1)
          ctx.move_to(x0, y0)
          ctx.line_to(x1, y1)
          ctx.stroke
        when 'C'
          ctx.set_source_rgb(0, 0, 0)
          cx, cy = seg[:center]
          radius = seg[:radius]
          if 0 < radius
            a0 = (90-seg[:a0]) * DEG_TO_RAD
            a1 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
            cx, cy = affine_transform(mat, cx, cy)
            a1 = rotate_angle(mat, a1)
            a0 = rotate_angle(mat, a0)
            ctx.arc(cx, cy, radius, a1, a0)
          else
            a0 = (90-seg[:a0]) * DEG_TO_RAD
            a1 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
            cx, cy = affine_transform(mat, cx, cy)
            a1 = rotate_angle(mat, a1)
            a0 = rotate_angle(mat, a0)
            ctx.arc(cx, cy, -radius, a1, a0)
          end
          ctx.stroke
        end
      }
    end
  }
end
