require 'cairo'

DEG_TO_RAD = Math::PI / 180

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
      ctx.save {
        ox, oy = h[:orig]
        angle = h[:angle]
        ctx.translate ox, oy
        ctx.rotate(-angle * DEG_TO_RAD)
        h[:segs].each {|seg|
          case seg[:type]
          when 'S'
            ctx.set_source_rgb(0, 0, 0)
            x0, y0 = seg[:pos0]
            x1, y1 = seg[:pos1]
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
              ctx.arc(cx, cy, radius, a1, a0)
            else
              a0 = (90-seg[:a0]) * DEG_TO_RAD
              a1 = (90-(seg[:a0]+seg[:a1])) * DEG_TO_RAD
              ctx.arc(cx, cy, -radius, a1, a0)
            end
            ctx.stroke
          end
        }
      }
    end
  }
end
