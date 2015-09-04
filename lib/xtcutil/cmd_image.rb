require 'cairo'
require 'optparse'

require 'xtcutil'
require 'xtcutil/cairo'

module Xtcutil
  class ImageCommand
    def initialize(layout)
      @layout = layout
      calc_scale
    end

    def calc_scale
      w, h = @layout.roomsize
      return 100, 100 if !w
      if !$xtcutil_image_size
        max_w = 8.0 * 72  # points
        max_h = 11.0 * 72 # points
      else
        max_w, max_h = $xtcutil_image_size
      end
      scale_x = max_w / w
      scale_y = max_h / h
      @scale = [scale_x, scale_y].min
      @image_w = (w * @scale).to_i
      @image_h = (h * @scale).to_i
    end

    def generate_png(output_filename)
      surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, @image_w, @image_h)
      ctx = Cairo::Context.new(surface)
      draw_xtc ctx
      surface.write_to_png(output_filename)
    end

    def generate_pdf(output_filename)
      surface = Cairo::PDFSurface.new(output_filename, @image_w, @image_h)
      ctx = Cairo::Context.new(surface)
      draw_xtc ctx
      ctx.show_page
      ctx.target.finish
    end

    def generate_svg(output_filename)
      surface = Cairo::SVGSurface.new(output_filename, @image_w, @image_h)
      ctx = Cairo::Context.new(surface)
      draw_xtc ctx
      ctx.show_page
      ctx.target.finish
    end

    def draw_xtc ctx
      ctx.save {
        ctx.translate 0, @image_h
        ctx.scale @scale, -@scale
        if $xtcutil_image_3d
          @layout.cairo_draw3d_layout ctx, $xtcutil_image_3d
        else
          @layout.cairo_draw_layout ctx
        end
      }
    end
  end

  class Xtcutil::CmdImage
    $xtcutil_image_format = 'png'
    $xtcutil_image_3d = nil
    $xtcutil_image_size = nil

    def op_image
      op = OptionParser.new
      op.banner = 'Usage: xtcutil image [options] xtcfile'
      op.def_option('--format=FORMAT', 'specify image format (png, pdf)') {|format|
        $xtcutil_image_format = format
      }
      op.def_option('--3d=[ZSCALE]', 'view 3D') {|zscale|
        if zscale
          $xtcutil_image_3d = zscale.to_f
        else
          $xtcutil_image_3d = 1.0
        end
      }
      op.def_option('--size=WxH', 'specify image size for raster images') {|arg|
        if /\A(\d+)x(\d+)\z/ !~ arg
          STDERR.puts "invalid size option: #{arg}"
          exit false
        end
        $xtcutil_image_size = [$1.to_i, $2.to_i]
      }
      op
    end

    def main_image(argv)
      op_image.parse!(argv)
      filename = argv[0]
      params = {}
      parsed = []
      Xtcutil::Parser.open_xtc(filename) {|f|
        Xtcutil::Parser.parse_io params, parsed, f
      }
      layout = Layout.new(parsed)
      if $xtcutil_image_3d
        layout.generate_graph
      end
      imagecommand = ImageCommand.new(layout)
      case $xtcutil_image_format
      when 'png'
        output_filename = filename.sub(/\.xtc\z/, '') + '.png'
        imagecommand.generate_png(output_filename)
      when 'pdf'
        output_filename = filename.sub(/\.xtc\z/, '') + '.pdf'
        imagecommand.generate_pdf(output_filename)
      when 'svg'
        output_filename = filename.sub(/\.xtc\z/, '') + '.svg'
        imagecommand.generate_svg(output_filename)
      else
        $stderr.puts "unexpected image format: #{$xtcutil_image_format}"
        exit false
      end
    end
  end
end
