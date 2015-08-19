require 'cairo'

class StraightLine
  def cairo_draw(ctx)
    ctx.move_to(@x0, @y0)
    ctx.line_to(@x1, @y1)
    ctx.stroke
  end
end

class CurveLine
  def cairo_draw(ctx)
    ctx.arc(@cx, @cy, @radius, @a0, @a1)
    ctx.stroke
  end
end

def cairo_draw_layout layout, ctx
  ctx.set_line_width 1
  layout.each_part {|part|
    part.each_track {|track|
      track.cairo_draw(ctx)
    }
  }
end
