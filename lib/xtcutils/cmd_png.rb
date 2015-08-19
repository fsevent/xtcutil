require 'cairo'

require 'xtcutils'
require 'xtcutils/cairo'

class PNGCommand
  def initialize(layout)
    @layout = layout
    calc_scale
  end

  def calc_scale
    w, h = @layout.roomsize
    return 100, 100 if !w
    max_w = 8.0 * 72  # points
    max_h = 11.0 * 72 # points
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

  def draw_xtc ctx
    ctx.save {
      ctx.translate 0, @image_h
      ctx.scale @scale, -@scale
      cairo_draw_layout @layout, ctx
    }
  end
end


def main_png(argv)
  filename = argv[0]
  params = {}
  parsed = []
  open_xtc(filename) {|f|
    parse_io params, parsed, f
  }
  layout = Layout.new(parsed)
  output_filename = filename.sub(/\.xtc\z/, '') + '.png'
  PNGCommand.new(layout).generate_png(output_filename)
end
