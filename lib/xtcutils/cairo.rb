require 'cairo'

def cairo_draw_height(ctx, x, y, h, node)
  ctx.save {
    ctx.set_line_width 0.1
    if node.get_attr(:defined_height)
      ctx.set_source_color("red")
    else
      ctx.set_source_color("black")
    end
    ctx.move_to(x, y)
    ctx.line_to(x, y + h)
    ctx.stroke
  }
end

class StraightLine
  def cairo_draw(ctx)
    ctx.move_to(@x0, @y0)
    ctx.line_to(@x1, @y1)
    ctx.stroke
  end

  def cairo_draw3d(ctx, zscale)
    n0 = self.get_node(0)
    n1 = self.get_node(1)
    h0 = ((n0 ? n0.get_node_height : nil) || 0.0) * zscale
    h1 = ((n1 ? n1.get_node_height : nil) || 0.0) * zscale
    cairo_draw_height(ctx, @x0, @y0, h0, n0)
    cairo_draw_height(ctx, @x1, @y1, h1, n1)
    ctx.move_to(@x0, @y0 + h0)
    ctx.line_to(@x1, @y1 + h1)
    ctx.stroke
  end
end

class CurveLine
  def cairo_draw(ctx)
    ctx.arc(@cx, @cy, @radius, @a0, @a1)
    ctx.stroke
  end

  def cairo_draw3d(ctx, zscale)
    n0 = self.get_node(0)
    n1 = self.get_node(1)
    h0 = ((n0 ? n0.get_node_height : nil) || 0.0) * zscale
    h1 = ((n1 ? n1.get_node_height : nil) || 0.0) * zscale
    x0, y0 = pos0
    x1, y1 = pos1
    cairo_draw_height(ctx, x0, y0, h0, n0)
    cairo_draw_height(ctx, x1, y1, h1, n1)
    ctx.save {
      nstep = 20
      ctx.move_to @cx + @radius * Math.cos(@a0),
                  @cy + @radius * Math.sin(@a0) + h0
      a1 = @a1
      1.upto(nstep) {|i|
        t = (i.to_f / nstep)
        a = @a0 * (1-t) + a1 * t
        h = h0 * (1-t) + h1 * t
        ctx.line_to @cx + @radius * Math.cos(a),
                    @cy + @radius * Math.sin(a) + h
      }
    }
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

def cairo_draw3d_layout layout, ctx, zscale=3.0
  ctx.set_line_width 1
  layout.each_part {|part|
    part.each_track {|track|
      track.cairo_draw3d(ctx, zscale)
    }
  }
end
