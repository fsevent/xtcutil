require 'gtk3'
require 'optparse'

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
    if $xtcutils_show_3d
      max_z = 0.0
      @layout.generate_graph.each {|node|
        z = node.get_node_height
        if max_z < z
          max_z = z
        end
      }
      @window_h += max_z * $xtcutils_show_3d
      @max_z = max_z
    else
      @max_z = 0.0
    end
  end

  def draw_callback
    ctx = @drawingarea.window.create_cairo_context
    draw_xtc ctx
  end

  def draw_xtc ctx
    ctx.save {
      ctx.translate 0, @window_h
      ctx.scale @scale, -@scale
      if $xtcutils_show_3d
        cairo_draw3d_layout @layout, ctx, $xtcutils_show_3d
      else
        cairo_draw_layout @layout, ctx
      end
    }
  end
end

$xtcutils_show_3d = nil

def op_show
  op = OptionParser.new
  op.banner = 'Usage: xtcutils show [options] xtcfile'
  op.def_option('--3d=[ZSCALE]', 'view 3D') {|zscale|
    if zscale
      $xtcutils_show_3d = zscale.to_f
    else
      $xtcutils_show_3d = 1.0
    end
  }
  op
end

def main_show(argv)
  op_show.parse!(argv)
  params = {}
  parsed = []
  open_xtc(argv[0]) {|f|
    parse_io params, parsed, f
  }
  layout = Layout.new(parsed)
  if $xtcutils_show_3d
    layout.generate_graph
  end
  Gtk.init
  XTCWindow.new(layout)
  Gtk.main
end
