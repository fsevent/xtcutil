require 'gtk3'

require 'xtcutils'
require 'xtcutils/cairo'

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
      cairo_draw_layout @layout, ctx
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
  XTCWindow.new(Layout.new(parsed))
  Gtk.main
end
