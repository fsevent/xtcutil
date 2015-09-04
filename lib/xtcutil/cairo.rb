require 'cairo'

module Xtcutil
  class AbstractLine
    def cairo_draw_height(ctx, pos, h, node)
      ctx.save {
        ctx.set_line_width 0.1
        if node.get_uniq_attr(:defined_height)
          ctx.set_source_color("cyan")
        else
          ctx.set_source_color("black")
        end
        ctx.move_to(pos[0], pos[1])
        ctx.line_to(pos[0], pos[1] + h)
        ctx.stroke
      }
    end
  end

  class StraightLine
    def cairo_draw(ctx)
      ctx.move_to(@pos0[0], @pos0[1])
      ctx.line_to(@pos1[0], @pos1[1])
      ctx.stroke
    end

    def cairo_draw3d(ctx, zscale)
      n0 = self.fetch_node(0)
      n1 = self.fetch_node(1)
      h0 = ((n0 ? n0.get_node_height : nil) || 0.0) * zscale
      h1 = ((n1 ? n1.get_node_height : nil) || 0.0) * zscale
      cairo_draw_height(ctx, @pos0, h0, n0)
      cairo_draw_height(ctx, @pos1, h1, n1)
      ctx.move_to(@pos0[0], @pos0[1] + h0)
      ctx.line_to(@pos1[0], @pos1[1] + h1)
      ctx.stroke
    end
  end

  class CurveLine
    def cairo_draw(ctx)
      ctx.arc(@center[0], @center[1], @radius, @a0, @a1)
      ctx.stroke
    end

    def cairo_draw3d(ctx, zscale)
      n0 = self.get_node(0)
      n1 = self.get_node(1)
      h0 = ((n0 ? n0.get_node_height : nil) || 0.0) * zscale
      h1 = ((n1 ? n1.get_node_height : nil) || 0.0) * zscale
      x0, y0 = pos0
      x1, y1 = pos1
      cairo_draw_height(ctx, pos0, h0, n0)
      cairo_draw_height(ctx, pos1, h1, n1)
      ctx.save {
        nstep = 20
        vec = Vector[Math.cos(@a0), Math.sin(@a0)]
        pos = @center + vec * @radius
        ctx.move_to pos[0], pos[1] + h0
        a1 = @a1
        1.upto(nstep) {|i|
          t = (i.to_f / nstep)
          a = @a0 * (1-t) + a1 * t
          h = h0 * (1-t) + h1 * t
          vec = Vector[Math.cos(a), Math.sin(a)]
          pos = @center + vec * @radius
          ctx.line_to pos[0], pos[1] + h
        }
      }
      ctx.stroke
    end
  end

  class Layout
    def cairo_draw_layout ctx
      ctx.set_line_width 0.5
      self.each_part {|part|
        part.each_track {|track|
          track.cairo_draw(ctx)
        }
      }
    end

    def cairo_draw3d_layout ctx, zscale=3.0
      ctx.set_line_width 0.5
      self.each_part {|part|
        part.each_track {|track|
          track.cairo_draw3d(ctx, zscale)
        }
      }
    end
  end
end
