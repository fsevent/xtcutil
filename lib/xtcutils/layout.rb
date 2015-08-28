class Layout
  def initialize(parsed)
    @parsed = parsed
  end
  attr_reader :parsed

  def roomsize
    return @roomsize if defined? @roomsize
    @parsed.each {|h|
      if h[:type] == 'roomsize'
        return @roomsize = [h[:x], h[:y]]
      end
    }
    return @roomsize = nil
  end

  def parts_ary
    return @parts_ary if defined? @parts_ary
    ary = []
    @parsed.each {|h|
      case h[:type]
      when 'straight'
        obj = StraightPart.new(self, h)
      when 'joint'
        obj = JointPart.new(self, h)
      when 'curve'
        obj = CurvePart.new(self, h)
      when 'turnout'
        obj = TurnoutPart.new(self, h)
      when 'turntable'
        obj = TurntablePart.new(self, h)
      else
        next
      end
      ary[obj.index] = obj
    }
    return @parts_ary = ary
  end

  def each_part(&b)
    parts_ary.each {|obj|
      next if obj.nil?
      yield obj
    }
  end

  def get_part(index)
    if 0 < index && index < parts_ary.length
      return parts[index] if parts[index]
      raise "unexpected part index: #{index}"
    end
    raise "part index out of range: #{index}"
  end

  def generate_graph
    return @node_ary if defined? @node_ary
    node_ary = []
    setup_inter_part_node(node_ary)
    setup_intra_part_node(node_ary)
    node_ary = clean_nodes(node_ary)
    setup_node_name(node_ary)
    #setup_elevation(node_ary)
    @node_ary = node_ary
  end

  def setup_inter_part_node(node_ary)
    hash = {}
    each_part {|obj|
      case obj
      when CurvePart
      when JointPart
      when StraightPart
      when TurnoutPart
      when TurntablePart
      else
        next
      end
      obj.each_seg {|ep|
        next if ep[:type] != 'E' && ep[:type] != 'T'
        if ep[:type] == 'E' # unconnected endpoint
          node_ary << (node = Node.new)
          obj.set_endpoint_node ep, node
          hash[node] = [obj.index]
        else # ep[:type] == 'T' # connected endpoint
          ep_index = ep[:index]
          if obj.index < ep_index
            node_ary << (node = Node.new)
            obj.set_endpoint_node ep, node
            hash[node] = [obj.index]
          else
            obj0 = parts_ary[ep_index]
            ep0 = obj0.nearest_connected_endpoint(ep[:pos])
            node = obj0.fetch_endpoint_node ep0
            obj.set_endpoint_node ep, node
            hash[node] << obj.index
            if 2 < hash[node].length
              raise "too many node at #{ep[:pos].inspect}"
            end
          end
        end
        if ep[:station_name] && /\S/ =~ ep[:station_name]
          node.set_node_name(ep[:station_name])
        end
        if ep[:elev_height]
          node.set_node_height(ep[:elev_height])
        end
      }
    }
  end

  def setup_intra_part_node(node_ary)
    each_part {|part|
      part.each_path {|path|
        startindex = startindex_for_path(path)
        if 0 < path.length
          define_node(part, path[0], startindex[0])
          last = path.length - 1
          define_node(part, path[last], 1-startindex[last])
        end
        1.upto(path.length-1) {|i|
          connect_line(node_ary,
                       path[i-1], 1-startindex[i-1],
                       path[i], startindex[i])
        }
      }
    }
  end

  def startindex_for_path(path)
    case path.length
    when 0
      []
    when 1
      [0]
    else
      i0, j0, d0 = nil, nil, nil
      0.upto(1) {|i|
        0.upto(1) {|j|
          d = hypot_pos(path[0].get_pos(i), path[1].get_pos(j))
          if d0.nil? || d < d0
            i0, j0, d0 = i, j, d
          end
        }
      }
      startindex = []
      startindex << (1 - i0)
      startindex << j0
      2.upto(path.length-1) {|i|
        last_endindex = 1 - startindex[-1]
        last_pos = path[i-1].get_pos(last_endindex)
        d0 = hypot_pos(last_pos, path[i].pos0)
        d1 = hypot_pos(last_pos, path[i].pos1)
        if d0 < d1
          startindex << 0
        else
          startindex << 1
        end
      }
      startindex
    end
  end

  def define_node(part, line, posindex)
    pos = line.get_pos(posindex)
    ep = part.nearest_endpoint(pos)
    ep_node = part.fetch_endpoint_node(ep)
    line_node = line.get_node(posindex)
    if line_node
      line_node.unify_node(ep_node)
    else
      line.set_node(posindex, ep_node)
    end
  end

  def connect_line(node_ary, line1, posindex1, line2, posindex2)
    node1 = line1.get_node(posindex1)
    node2 = line2.get_node(posindex2)
    if !node1
      if !node2
        node_ary << (node = Node.new)
        line1.set_node(posindex1, node)
        line2.set_node(posindex2, node)
      else
        line1.set_node(posindex1, node2)
      end
    else
      if !node2
        line2.set_node(posindex2, node1)
      else
        node1.unify_node(node2)
      end
    end
  end

  def clean_nodes(node_ary)
    node_ary = node_ary.reject {|node| !node.equal?(node.unified_node) }
    node_ary.each {|node|
      node.each_line {|line, posindex|
        line.fetch_node(0)
        line.fetch_node(1)
      }
    }
  end

  def setup_node_name(node_ary)
    i = 0
    node_ary.each {|n|
      if !n.get_node_name
        n.set_node_name("n#{i += 1}")
      end
    }
  end

end
