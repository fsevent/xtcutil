require 'gtk3'

require 'xtcutils'

DEG_TO_RAD = Math::PI / 180

class XTCWindow < Gtk::Window
  def initialize(layout)
    @layout = layout

    super()

    set_title "xtcutils"
    signal_connect "destroy" do
      Gtk.main_quit
    end

    @drawingarea = Gtk::DrawingArea.new
    @drawingarea.signal_connect "draw" do
      draw_callback
    end
    add @drawingarea

    calc_scale
    set_default_size @window_w, @window_h
    set_window_position :center
    show_all
  end

  def calc_scale
    w, h = @layout.roomsize
    return 100, 100 if !w
    max_w = 700
    max_h = 500
    max_w = 1200
    max_h = 1200
    scale_x = max_w / w
    scale_y = max_h / h
    @scale = [scale_x, scale_y].min
    @window_w = (w * @scale).to_i
    @window_h = (h * @scale).to_i
  end

  def draw_callback
    ctx = @drawingarea.window.create_cairo_context
    draw_xtc ctx
  end

  def draw_xtc ctx
    ctx.save {
      ctx.translate 0, @window_h
      ctx.scale @scale, -@scale
      ctx.set_line_width 1
      @layout.parsed.each {|h|
        case h[:type]
        when 'straight'
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
          a0 = (-h[:segs][0][:angle]) * DEG_TO_RAD
          a1 = (180-h[:segs][1][:angle]) * DEG_TO_RAD
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
    }
  end
end


def main_show(argv)
  params = {}
  parsed = []
  open_xtc(argv[0]) {|f|
    parse_io params, parsed, f
  }
  Gtk.init
  window = XTCWindow.new(Layout.new(parsed))
  Gtk.main
end
