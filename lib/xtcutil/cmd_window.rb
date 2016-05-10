# cmd_window --- "window" subcommand implementation
#
# Copyright (C) 2015  National Institute of Advanced Industrial Science and Technology (AIST)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

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
      if $xtcutil_window_3d
        max_z = 0.0
        @layout.generate_graph.each {|node|
          z = node.get_node_height
          if max_z < z
            max_z = z
          end
        }
        @window_h += max_z * $xtcutil_window_3d
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
        if $xtcutil_window_3d
          @layout.cairo_draw3d_layout ctx, $xtcutil_window_3d
        else
          @layout.cairo_draw_layout ctx
        end
      }
    end
  end

  module_function

  $xtcutil_window_3d = nil

  def window_op
    op = OptionParser.new
    op.banner = 'Usage: xtcutil window [options] xtcfile'
    op.def_option('--3d=[ZSCALE]', 'view 3D') {|zscale|
      if zscale
        $xtcutil_window_3d = zscale.to_f
      else
        $xtcutil_window_3d = 1.0
      end
    }
    op
  end

  def window_main(argv)
    window_op.parse!(argv)
    parsed = Xtcutil::Parser.parse_file(argv[0])
    layout = Xtcutil::Layout.new(parsed)
    if $xtcutil_window_3d
      layout.generate_graph
    end
    Gtk.init
    XTCWindow.new(layout)
    Gtk.main
  end
end
