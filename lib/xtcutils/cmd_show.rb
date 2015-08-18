require 'gtk3'

require 'xtcutils/parser'

class XTCWindow < Gtk::Window
  def initialize(params, parsed)
    @params = params
    @parsed = parsed

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

    set_default_size 400, 200
    set_window_position :center
    show_all
  end

  def draw_callback
    ctx = @drawingarea.window.create_cairo_context
    draw_xtc ctx
  end

  def draw_xtc ctx
    ctx.save {
      ctx.scale 10, 10
      ctx.set_line_width 1
      @parsed.each {|h|
        if h[:type] == 'straight'
          x1, y1 = h[:segs][0][:pos]
          x2, y2 = h[:segs][1][:pos]
          ctx.move_to(x1, y1)
          ctx.line_to(x2, y2)
          ctx.stroke
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
  window = XTCWindow.new(params, parsed)
  Gtk.main
end
