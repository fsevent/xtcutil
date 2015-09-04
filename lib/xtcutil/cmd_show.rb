require 'gtk3'
require 'optparse'

require 'xtcutil'
require 'xtcutil/cairo'

module Xtcutil
  class XTCWindow < Gtk::Window
    def initialize(layout)
      @layout = layout

      super()

      set_title "xtcutil"
      signal_connect "destroy" do
        Gtk.main_quit
      end

      @drawingarea = Gtk::DrawingArea.new
      @drawingarea.signal_connect "draw" do
        draw_callback
      end
      add @drawingarea

      signal_connect "key_press_event" do |widget, event|
        if event.state == 0
          case event.keyval
          when Gdk::Keyval::GDK_KEY_q
            Gtk.main_quit()
          end
        elsif event.state == :control_mask
          case event.keyval
          when Gdk::Keyval::GDK_KEY_c
            Gtk.main_quit()
          end
        end
      end

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
      if $xtcutil_show_3d
        max_z = 0.0
        @layout.generate_graph.each {|node|
          z = node.get_node_height
          if max_z < z
            max_z = z
          end
        }
        @window_h += max_z * $xtcutil_show_3d
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
        if $xtcutil_show_3d
          @layout.cairo_draw3d_layout ctx, $xtcutil_show_3d
        else
          @layout.cairo_draw_layout ctx
        end
      }
    end
  end

  class CmdShow
    $xtcutil_show_3d = nil

    def op_show
      op = OptionParser.new
      op.banner = 'Usage: xtcutil show [options] xtcfile'
      op.def_option('--3d=[ZSCALE]', 'view 3D') {|zscale|
        if zscale
          $xtcutil_show_3d = zscale.to_f
        else
          $xtcutil_show_3d = 1.0
        end
      }
      op
    end

    def main_show(argv)
      op_show.parse!(argv)
      params = {}
      parsed = []
      Xtcutil::Parser.open_xtc(argv[0]) {|f|
        Xtcutil::Parser.parse_io params, parsed, f
      }
      layout = Xtcutil::Layout.new(parsed)
      if $xtcutil_show_3d
        layout.generate_graph
      end
      Gtk.init
      XTCWindow.new(layout)
      Gtk.main
    end
  end
end
