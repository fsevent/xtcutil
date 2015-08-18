ELEV_NONE = 0
ELEV_DEF = 1
ELEV_COMP = 2
ELEV_GRADE = 3
ELEV_IGNORE = 4
ELEV_STATION = 5
ELEV_MASK = 0x07

CAR_ITEM_HASNOTES = (1<<8)
CAR_ITEM_ONLAYOUT = (1<<9)

def color_from_rgb(rgb)
  b = rgb & 0xff
  g = (rgb >> 8) & 0xff
  r = (rgb >> 16) & 0xff
  sprintf("\#%02X%02X%02X", r, g, b)
end

def get_args(format, str)
  ret = []
  while !format.empty?
    str = str.sub(/\A\s*/, '')
    #p [format, str]
    case format
    when /\A0/
      format = $'
      raise "integer expected" if /\A(\d+)/ !~ str
      str = $'
    when /\A[XZ]/
      format = $'
      ret << 0
    when /\AY/
      format = $'
      ret << 0.0
    when /\A[Ldl]/
      format = $'
      raise "integer expected" if /\A([-+]?\d+)/ !~ str
      ret << $1.to_i
      str = $'
    when /\Af/
      format = $'
      raise "float expected" if /\A([-+]?\d+(?:\.\d+)?(?:e[-+]?\d+)?)/ !~ str
      ret << $1.to_f
      str = $'
    when /\Aw/
      format = $'
      raise "w arg expected" if /\A([-+]?\d+)(\.\d+)?/ !~ str
      if $2
        ret << "#{$1}#{$2}".to_f
      else
        ret << $1.to_i / 1440.0 # 1440.0 may be invalid.
      end
      str = $'
    when /\Ap/
      format = $'
      raise "float expected" if /\A([-+]?\d+(?:\.\d+)?(?:e[-+]?\d+)?)\s+([-+]?\d+(?:\.\d+)?(?:e[-+]?\d+)?)/ !~ str
      ret << [$1.to_f, $2.to_f]
      str = $'
    when /\As/
      format = $'
      raise "non-quoted string expected" if /\A(\S+)/ !~ str
      ret << $1
      str = $'
    when /\Aq/
      format = $'
      raise "quoted string expected" if /\A"((?:[^"]|"")*)"/ !~ str
      str = $'
      ret << $1.gsub(/""/, '"')
    when /\Ac/
      format = $'
      ret << str.dup
      # don't skip str.
    else
      raise "unexpected format: #{format}"
    end
  end
  ret
end

def parse_segs(params, segs, io)
  while line = io.gets
    line.sub!(/\A\s*/, '')
    if /\AEND/ =~ line
      break
    elsif /\A(\#|\n|\z)/ =~ line
      # ignore comment and empty line
    elsif /\A(.)(3)?/ =~ line
      type = $1
      has_elev = $2
      args = $'.sub(/\A\s*/, '')
      case type
      when 'L' # SEG_STRLIN
        rgb, width, pos0, elev0, pos1, elev1 = get_args(has_elev ? "lwpfpf":"lwpYpY", args)
        segs << { type:type, color:color_from_rgb(rgb), width:width, pos0:pos0, pos1:pos1 }
      when 'Q' # SEG_TBLEDGE
        rgb, width, pos0, elev0, pos1, elev1 = get_args(has_elev ? "lwpfpf":"lwpYpY", args)
        segs << { type:type, color:color_from_rgb(rgb), width:width, pos0:pos0, pos1:pos1 }
      when 'M' # SEG_DIMLIN
        rgb, width, pos0, elev0, pos1, elev1, option = get_args(has_elev ? "lwpfpfl":"lwpYpYZ", args)
        segs << { type:type, color:color_from_rgb(rgb), width:width, pos0:pos0, pos1:pos1, option:option }
      when 'B' # SEG_BENCH
        rgb, width, pos0, elev0, pos1, elev1, option = get_args(has_elev ? "lwpfpfl":"lwpYpYZ", args)
        #option = BenchInputOption(option)
        segs << { type:type, color:color_from_rgb(rgb), width:width, pos0:pos0, pos1:pos1, option:option }
      when 'A' # SEG_CRVLIN
        rgb, width, radius, center, elev0, a0, a1 = get_args(has_elev ? "lwfpfff":"lwfpYff", args)
        segs << { type:type, color:color_from_rgb(rgb), width:width, radius:radius, center:center, a0:a0, a1:a1 }
      when 'S' # SEG_STRTRK
        rgb, width, pos0, elev0, pos1, elev1 = get_args(has_elev ? "lwpfpf":"lwpYpY", args)
        segs << { type:type, color:color_from_rgb(rgb), width:width, pos0:pos0, pos1:pos1 }
      when 'C' # SEG_CRVTRK
        rgb, width, radius, center, elev0, a0, a1 = get_args(has_elev ? "lwfpfff":"lwfpYff", args)
        segs << { type:type, color:color_from_rgb(rgb), radius:radius, center:center, a0:a0, a1:a1 }
      when 'J' # SEG_JNTTRK
        rgb, width, pos, elev0, angle, l0, l1, r, l, option = get_args(has_elev ? "lwpffffffl":"lwpYfffffl", args)
        negate = (option&1) != 0
        flip = (option&2)!= 0
        scurve = (option&4) != 0
        segs << { type:type, color:color_from_rgb(rgb), width:width, pos:pos, angle:angle, l0:l, R:r, L:l, negate:negate, filp:flip, scurve:scurve }
      when 'G' # SEG_FILCRCL
        rgb, width, radius, center, elev0 = get_args(has_elev ? "lwfpf":"lwfpY", args)
        a0 = 0.0;
        a1 = 360.0;
        segs << { type:type, color:color_from_rgb(rgb), width:width, radius:radius, center:center, a0:a0, a1:a1 }
      when 'Y', 'F' # SEG_POLY, SEG_FILPOLY
        rgb, width, cnt = get_args("lwd", args)
        pts = []
        cnt.times {
          line = io.gets
          if !line
            pts << :unexpected_EOF
            break
          end
          pt, elev0 = get_args(has_elev ? "pf":"pY", line)
          pts << pt
        }
        angle = 0.0
        orig = [0.0, 0.0]
        segs << { type:type, color:color_from_rgb(rgb), width:width, angle:angle, orig:orig, pts:pts }
      when 'Z' # SEG_TEXT
        rgb, pos, angle, fontSize, string = get_args("lpf0fq", args)
        segs << { type:type, color:color_from_rgb(rgb), pos:pos, angle:angle, fontSize:fontSize, string:string }
      when 'E', 'T' # SEG_UNCEP, SEG_CONEP
        if type == 'T'
          index, args = get_args('dc', args)
        else
          index = nil
        end
        pos, angle, args = get_args('pfc', args)
        elev_option = 0
        elev_height = 0.0
        elev_doff = [0.0, 0.0]
        option = 0
        if /\S/ =~ args
          if params[:version] < 7
            elev_option, elev_height, elev_doff = get_args('dfp', args)
          else
            option, elev_doff, args = get_args('lpc', args)
            elev_option = option & 0xff
            option >>= 8
            case elev_option & ELEV_MASK
            when ELEV_DEF
              height, args = get_args('fc', args)
            when ELEV_STATION
              name, args = get_args('qc', args)
            end
          end
        end
        seg = { type:type }
        seg[:index] = index if index
        seg[:pos] = pos
        seg[:angle] = angle
        seg[:option] = option
        seg[:elev_option] = elev_option
        seg[:elev_height] = elev_height
        seg[:elev_doff] = elev_doff
        segs << seg
      when 'P' # SEG_PATH
        if /\A"([^"]*)"\s*/ !~ args
          raise "quoted name expected: #{args}"
        end
        name = $1
        path = $'.split(/\s+/).map {|s| s.to_i }
        segs << { type:type, name:name, path:path }
      when 'X' # SEG_SPEC
        temp_special = args
        segs << { type:type, special:temp_special }
      when 'U' # SEG_CUST
        temp_custom = args
        segs << { type:type, custom:temp_custom }
      when 'D' # SEG_DOFF
        x, y = get_args('ff', args)
        segs << { type:type, x:x, y:y }
      else
        segs << { type: 'unexpected', lineno: io.lineno, line: line }
      end
    else
      segs << { type: 'unexpected', lineno: io.lineno, line: line }
    end
  end
end

def parse_turnout(params, result, args, io)
  if params[:version] < 3
    options = 0
    position = 0
    index, layer,                    scale, visible, orig,       angle, title = get_args('dXsdpfq', args)
  elsif params[:version] < 9
    index, layer, options, position, scale, visible, orig, elev, angle, title = get_args('dLll0sdpYfq', args)
  else
    index, layer, options, position, scale, visible, orig, elev, angle, title = get_args('dLll0sdpffq', args)
  end
  segs = []
  parse_segs(params, segs, io)
  h = {
    type:'turnout',
    index:index,
    layer:layer,
    options:options,
    width:options&3,
    handlaid:(options&0x08)!=0,
    flipped:(options&0x10)!=0,
    ungrouped:(options&0x20)!=0,
    split:(options&0x40)!=0,
    hidedesc:(options&0x80)!=0,
    position:position,
    scale:scale,
    visible:visible,
    orig:orig,
    angle:angle,
    title:title,
    segs:segs
  }
  result << h
end

def parse_turntable(params, result, args, io)
  if params[:version] < 3
    index, layer, scale, visible, pos, elev, radius, curr_ep = get_args('dXsdpYfX', args)
  elsif params[:version] < 9
    index, layer, scale, visible, pos, elev, radius, curr_ep = get_args('dL000sdpYfX', args)
  elsif params[:version] < 10
    index, layer, scale, visible, pos, elev, radius, curr_ep = get_args('dL000sdpffX', args)
  else
    index, layer, scale, visible, pos, elev, radius, curr_ep = get_args('dL000sdpffd', args)
  end
  segs = []
  parse_segs(params, segs, io)
  h = {
    type:'turntable',
    index:index,
    layer:layer,
    scale:scale,
    visible:visible,
    pos:pos,
    radius:radius,
    curr_ep:curr_ep,
    segs:segs
  }
  result << h
end

def parse_structure(params, result, args, io)
  if params[:version] < 3
    options = 0
    position = 0
    index, layer,                    scale, visible, orig,       angle, title = get_args('dXsdpfq', args)
  elsif params[:version] <= 5
    index, layer,                    scale, visible, orig,       angle, title = get_args('dL00sdpfq', args)
  elsif params[:version] < 9
    index, layer, options, position, scale, visible, orig, elev, angle, title = get_args('dLll0sdpYfq', args)
  else
    index, layer, options, position, scale, visible, orig, elev, angle, title = get_args('dLll0sdpffq', args)
  end
  segs = []
  parse_segs(params, segs, io)
  h = {
    type:'structure',
    index:index,
    layer:layer,
    options:options,
    width:options&3,
    handlaid:(options&0x08)!=0,
    flipped:(options&0x10)!=0,
    ungrouped:(options&0x20)!=0,
    split:(options&0x40)!=0,
    hidedesc:(options&0x80)!=0,
    position:position,
    scale:scale,
    visible:visible,
    orig:orig,
    angle:angle,
    title:title,
    segs:segs
  }
  result << h
end

def parse_draw(params, result, args, io)
  if params[:version] < 3
    index, layer, orig, elev, angle = get_args("dXpYf", args)
  elsif params[:version] < 9
    index, layer, orig, elev, angle = get_args("dL000pYf", args)
  else
    index, layer, orig, elev, angle = get_args("dL000pff", args)
  end
  segs = []
  parse_segs(params, segs, io)
  h = {
    type:'draw',
    index:index,
    layer:layer,
    orig:orig,
    angle:angle,
    segs:segs
  }
  result << h
end

def parse_joint(params, result, args, io)
  if params[:version] < 3
    index, layer, options, scale, visible, l0, l1, r, l, flip, negate, scurve, pos, elev, angle = get_args("dXZsdffffdddpYf", args)
  elsif params[:version] < 9
    index, layer, options, scale, visible, l0, l1, r, l, flip, negate, scurve, pos, elev, angle = get_args("dLl00sdffffdddpYf", args)
  else
    index, layer, options, scale, visible, l0, l1, r, l, flip, negate, scurve, pos, elev, angle = get_args("dLl00sdffffdddpff", args)
  end
  segs = []
  parse_segs(params, segs, io)
  h = {
    type:'joint',
    index:index,
    layer:layer,
    options:options,
    width:options&3,
    scale:scale,
    visible:visible,
    l0:l0,
    l1:l1,
    r:r,
    l:l,
    flip:flip,
    negate:negate,
    scurve:scurve,
    pos:pos,
    angle:angle,
    segs: segs
  }
  result << h
end

def parse_straight(params, result, args, io)
  if params[:version] < 3
    index, layer, options, scale, visible = get_args("dXZsd", args)
  else
    index, layer, options, scale, visible = get_args("dLl00sd", args)
  end
  segs = []
  parse_segs(params, segs, io)
  h = {
    type:'straight',
    index:index,
    layer:layer,
    options:options,
    width:options&3,
    scale:scale,
    visible:visible,
    segs:segs
  }
  result << h
end

def parse_curve(params, result, args, io)
  if params[:version] < 3
    index, layer, options, scale, visible, pos, elev, radius, args = get_args("dXZsdpYfc", args)
  elsif params[:version] < 9
    index, layer, options, scale, visible, pos, elev, radius, args = get_args("dLl00sdpYfc", args)
  else
    index, layer, options, scale, visible, pos, elev, radius, args = get_args("dLl00sdpffc", args)
  end
  if /\S/ =~ args
    helix_turns, description_off = get_args("lp", args)
  else
    helix_turns = 0
    description_off = [0.0, 0.0]
  end
  segs = []
  parse_segs(params, segs, io)
  h = {
    type:'curve',
    index:index,
    layer:layer,
    options:options,
    width:options&3,
    hidedesc:(options&0x80)!=0,
    pos:pos,
    radius:radius,
    helix_turns:helix_turns,
    description_off:description_off,
    segs:segs
  }
  result << h
end

def parse_note(params, result, args, io)
  if /\AMAIN/ =~ args
    size = get_args(params[:version] < 3 ? 'd' : '000d', $')
  else
    index, layer, pos, elev, size = get_args(
      params[:version] < 3 ? 'XXpYd' :
      params[:version] < 9 ? 'dL00pYd' : 'dL00pfd',
      args)
  end
  text = ''
  while /\A    END/ !~ (line = io.gets)
    text << line
  end
  h = { type: 'note' }
  h[:index] = index if index
  h[:pos] = pos if pos
  h[:layer] = layer if layer
  h[:text] = text
  result << h
end

def parse_tableedge(params, result, args, io)
  if params[:version] < 3
    index, layer, pos0, elev0, pos1, elev1 = get_args("dXpYpY", args)
  elsif params[:version] < 9
    index, layer, pos0, elev0, pos1, elev1 = get_args("dL000pYpY", args)
  else
    index, layer, pos0, elev0, pos1, elev1 = get_args("dL000pfpf", args)
  end
  result << { type:'tableedge', index:index, layer:layer, pos0:pos0, pos1:pos1 }
end

def parse_text(params, result, args, io)
  if params[:version] < 3
    index, layer, pos, angle, text, text_size = get_args("XXpYql", args)
  elsif params[:version] < 9
    index, layer, pos, angle, text, text_size = get_args("dL000pYql", args)
  else
    index, layer, pos, angle, text, text_size = get_args("dL000pfql", args)
  end
  result << { type:'text', index:index, layer:layer, pos:pos, angle:angle, text:text, text_size:text_size }
end

def parse_car(params, result, args, io)
  item_index, scale, title, options, type,
    car_length, car_width, truck_center, coupled_length, rgb,
    purch_price, curr_price, condition, purch_date, service_date,
    args = get_args("lsqll" "ff00ffl" "fflll000000c", args)
  if (options & CAR_ITEM_HASNOTES) != 0
    notes = ''
    while /\A    END/ !~ (line = io.gets)
      notes << line
    end
  end
  if (options & CAR_ITEM_ONLAYOUT) != 0
    index, layer, pos, angle = get_args('dLpf', args)
    segs = []
    parse_segs(params, segs, io)
  end
  h = {
    type:'car',
    car_length:car_length,
    car_width:car_width,
    truck_center:truck_center,
    coupled_length:coupled_length,
    color:color_from_rgb(rgb),
    purch_price:purch_price,
    curr_price:curr_price,
    condition:condition,
    purch_date:purch_date,
    service_date:service_date,
  }
  h[:notes] = notes if notes
  h[:index] = index if index
  h[:layer] = layer if layer
  h[:pos] = pos if pos
  h[:angle] = angle if angle
  h[:segs] = segs if segs
  result << h
end

def parse_track(params, result, args, io)
  case args
  #when /\ANOTRACK/
  when /\AJOINT/
    parse_joint(params, result, $', io)
  when /\ATURNOUT /
    parse_turnout(params, result, $', io)
  when /\ANOTE /
    parse_note(params, result, $', io)
  when /\ADRAW/
    parse_draw(params, result, $', io)
  when /\ATURNTABLE/
    parse_turntable(params, result, $', io)
  when /\ASTRUCTURE /
    parse_structure(params, result, $', io)
  when /\ACAR/
    parse_car(params, result, $', io)
  when /\ASTRAIGHT/
    parse_straight(params, result, $', io)
  when /\ACURVE/
    parse_curve(params, result, $', io)
  when /\ATABLEEDGE /
    parse_tableedge(params, result, $', io)
  when /\ATEXT /
    parse_text(params, result, $', io)
  else
    return false
  end
  true
end

def parse_io(params, result, io)
  while line = io.gets
    if /\A\#/ =~ line
      comment = $'
      result << { type: 'comment', comment: comment }
    elsif /\A(\n|\z)/ =~ line
      # result << { type: 'empty' }
    elsif parse_track(params, result, line, io)
      # parse_track parsed track.
    elsif /\AEND/ =~ line
      break
    elsif /\AVERSION\s+(\d+)\s*(\S.*)\n\z/ =~ line
      version_number = $1.to_i
      version_string = $2
      result << { type: 'version', version_number: version_number, version_string: version_string }
      params[:version] = version_number
    elsif /\AVERSION\s+(\d+)/ =~ line
      version_number = $1.to_i
      result << { type: 'version', version_number: version_number }
      params[:version] = version_number
    elsif /\ATITLE1 (.*)\n\z/ =~ line
      title1 = $1
      result << { type: 'title1', title1: title1 }
    elsif /\ATITLE2 (.*)\n\z/ =~ line
      title2 = $1
      result << { type: 'title2', title2: title2 }
    elsif /\AROOMSIZE\s+(\S+)\s*[xX]\s*(\S+)/ =~ line
      size_x = $1.to_f
      size_y = $2.to_f
      result << { type: 'roomsize', x: size_x, y: size_y }
    elsif /\ASCALE\s+(\S+)/ =~ line
      scale = $1 # HO, ...
      result << { type: 'scale', scale: scale }
    elsif /\AMAPSCALE\s+(\d+)/ =~ line
      mapscale = $1.to_i
      result << { type: 'mapscale', mapscale: mapscale }
    elsif /\ALAYERS\s+CURRENT\s+(\d+)/ =~ line
      current_layer = $1.to_i
      result << { type: 'layers_current', current_layer: current_layer }
    elsif /\ALAYERS\s+/ =~ line
      inx, visible, frozen, on_map, rgb, name = get_args('ddddl0000q', $')
      result << { type: 'layers', inx: inx, visible: visible, frozen: frozen, on_map: on_map, rgb: rgb, name: name }
    else
      result << { type: 'unexpected', lineno: io.lineno, line: line }
    end
  end
  result
end
