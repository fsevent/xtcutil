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
    e_nodes = setup_inter_part_node
    connect_close_endpoints(e_nodes)
    setup_intra_part_node
    node_ary = collect_nodes
    node_ary = reorder_nodes(node_ary)
    setup_node_name(node_ary)
    setup_line_name(node_ary)
    setup_elevation(node_ary)
    @node_ary = node_ary
  end

  def setup_inter_part_node
    e_nodes = {}
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
      ep_num = 0
      node_pairs = []
      obj.each_seg {|ep|
        next if ep[:type] != 'E' && ep[:type] != 'T'
        ep_num += 1
        node = Node.new
        node.add_comment "T#{obj.index}EP#{ep_num}#{ep[:type]}"
        node.add_list_attr :ep_pos, ep[:pos]
        node.add_list_attr :ep_angle, ((90 - ep[:angle]) % 360) * DEG_TO_RAD
        obj.set_endpoint_node ep, node
        if ep[:station_name] && /\S/ =~ ep[:station_name]
          node.set_node_name(ep[:station_name].strip.gsub(/\s+/, '_'))
        end
        if ep[:elev_height]
          node.set_node_height(ep[:elev_height])
          node.set_uniq_attr(:defined_height, true)
        end
        if ep[:type] == 'E' # unconnected endpoint
          e_nodes[node] = ep[:pos]
        else # ep[:type] == 'T' # connected endpoint
          ep_index = ep[:index]
          obj0 = parts_ary[ep_index]
          ep0 = obj0.nearest_connected_endpoint_from(ep[:pos], obj.index)
          node0 = obj0.get_endpoint_node ep0
          node_pairs << [node, node0] if node0
        end
      }
      node_pairs.each {|node1, node2|
        node = node1.unify_node(node2)
        if 2 < node.count_list_attr(:ep_pos)
          ep_pos_list = node.get_list_attr(:ep_pos)
          raise "too many node at #{ep_pos_list[0].inspect}: #{node.get_list_attr(:comments).inspect}"
        end
        angle1, angle2 = node.get_list_attr(:ep_angle)
        tolerance = 45.0 * DEG_TO_RAD
        a1, a2 = angle1, angle2
        a1 += Math::PI # opposite direction
        a1 -= 2 * Math::PI if 2 * Math::PI <= a1
        d = (a1 - a2).abs
        if tolerance < d && tolerance < (d - 2 * Math::PI).abs
          raise "inter part node angle too bend: #{angle1} #{angle2}"
        end
      }
    }
    e_nodes
  end

  def connect_close_endpoints(e_nodes)
    threshold = 0.1 # nodes nearer than threshold are unified.
    e_nodes = e_nodes.to_a.sort_by {|n, pos| pos[0] } # sort by x.
    e_nodes.each_with_index {|(n0, pos0), i|
      (i-1).downto(0) {|j|
        n1, pos1 = e_nodes[j]
        break if threshold <= pos0[0] - pos1[0]
        next if threshold <= (pos0[1] - pos1[1]).abs
        if hypot_pos(pos0, pos1) < threshold
          n0.unify_node(n1)
          break
        end
      }
    }
  end

  def setup_intra_part_node
    each_part {|part|
      part.each_path {|path, has_start_ep, has_end_ep|
        startindex = startindex_for_path(path)
        if 0 < path.length
          if has_start_ep
            define_node(part, path[0], startindex[0])
          end
          last = path.length - 1
          if has_end_ep
            define_node(part, path[last], 1-startindex[last])
          end
        end
        1.upto(path.length-1) {|i|
          connect_line(path[i-1], 1-startindex[i-1],
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

  def define_node(part, line, tipindex)
    pos = line.get_pos(tipindex)
    ep = part.nearest_endpoint(pos)
    ep_node = part.fetch_endpoint_node(ep)
    line_node = line.get_node(tipindex)
    line_node.unify_node(ep_node)
  end

  def connect_line(line1, tipindex1, line2, tipindex2)
    node1 = line1.get_node(tipindex1)
    node2 = line2.get_node(tipindex2)
    node1.unify_node(node2)
  end

  def collect_nodes
    h = {}
    each_part {|part|
      part.each_track {|line|
        0.upto(1) {|i|
          h[line.get_node(i).unified_node] = true
        }
      }
    }
    h.keys
  end

  def reorder_nodes(node_ary)
    h = {}
    [
      lambda {|n| n.num_lines < 2 },
      lambda {|n| n.num_lines > 2 },
      lambda {|n| true },
    ].each {|node_selector|
      node_ary.each {|n0|
        next if h.has_key? n0
        if node_selector.call(n0)
          q = [n0]
          until q.empty?
            n1 = q.pop
            h[n1] = h.size
            n1.each_line {|tipindex, line|
              n2 = line.get_node(1-tipindex)
              next if h.has_key? n2
              q.push n2
            }
          end
        end
      }
    }
    h.keys # sorted by the hash value
  end

  def setup_node_name(node_ary)
    i = 0
    node_ary.each {|n|
      if !n.get_node_name
        n.set_node_name("v#{i += 1}")
      end
    }
  end

  def setup_line_name(node_ary)
    i = 0
    node_ary.each {|n|
      n.each_line {|tipindex, line|
        if !line.get_line_name
          line.set_line_name("e#{i += 1}")
        end
      }
    }
  end

  def setup_elevation(node_ary)
    node_ary.each {|n|
      next if !n.get_node_height
      each_elevation_computation_area(n) {|visited, paths_hash|
        if visited.keys.count {|node| node.get_node_height } == 1
          height = n.get_node_height
          visited.keys.each {|node| node.set_node_height height }
        else
          compute_elevation(n, visited, paths_hash)
        end
      }
    }
    node_ary.each {|n|
      next if n.get_node_height
      n.set_node_height 0.0
    }
  end

  PathElem = Struct.new("PathElem", :tipindex1, :line, :tipindex2, :node)

  def each_elevation_computation_area(n0)
    n0.each_line {|tipindex_a1, line_a|
      paths_hash = {}
      tipindex_a2 = 1-tipindex_a1
      n1 = line_a.get_node(tipindex_a2)
      next if n1.get_node_height
      visited = { n0 => true, n1 => true }
      q = []
      if n1.num_lines == 2
        q.push [n0, [PathElem[tipindex_a1, line_a, tipindex_a2, n1]], n1]
      else
        paths_hash[n0] ||= {}
        paths_hash[n0][n1] ||= []
        paths_hash[n0][n1] << [PathElem[tipindex_a1, line_a, tipindex_a2, n1]]
        q.push [n1, [], n1]
      end
      until q.empty?
        n1, path, n2 = q.pop
        n2.each_line {|tipindex_b1, line_b|
          tipindex_b2 = 1-tipindex_b1
          n3 = line_b.get_node(tipindex_b2)
          next if !path.empty? && path.last.line == line_b
          path3 = path + [PathElem[tipindex_b1, line_b, tipindex_b2, n3]]
          if n3.get_node_height || n3.num_lines != 2
            paths_hash[n1] ||= {}
            paths_hash[n1][n3] ||= []
            paths_hash[n1][n3] << path3
            path3 = []
            n4 = n3
          else
            n4 = n1
          end
          next if visited[n3]
          visited[n3] = true
          next if n3.get_node_height
          q.push [n4, path3, n3]
        }
      end
      yield visited, paths_hash
    }
  end

  def compute_elevation(n, visited, paths_hash)
    dh = make_distance_hash(paths_hash)
    non_channel_nodes = dh.keys
    update_to_shortest_path_distances(dh)
    hh = make_defined_height_hash(non_channel_nodes)
    set_non_channel_node_height(non_channel_nodes, dh, hh)
    set_channel_node_height(paths_hash)
  end

  def make_distance_hash(paths_hash)
    dh = {}
    paths_hash.each {|n1, h|
      h.each {|n2, paths|
        distance_min = nil
        paths.each {|path|
          distance = 0.0
          path.each {|pathelem|
            distance += pathelem.line.distance
          }
          if !distance_min || distance < distance_min
            distance_min = distance
          end
        }
        dh[n1] ||= {}
        dh[n1][n2] = distance_min
        dh[n2] ||= {}
        dh[n2][n1] = distance_min
      }
    }
    dh
  end

  def update_to_shortest_path_distances(dh)
    # Warshall-Floyd Algorithm
    ns = dh.keys
    ns.each {|nk|
      ns.each {|ni|
        ns.each {|nj|
          next if !dh[ni][nk]
          next if !dh[nk][nj]
          if !dh[ni][nj] || dh[ni][nk] + dh[nk][nj] < dh[ni][nj]
            dh[ni][nj] = dh[ni][nk] + dh[nk][nj]
          end
        }
      }
    }
  end

  def make_defined_height_hash(non_channel_nodes)
    h = {}
    non_channel_nodes.each {|n|
      height = n.get_node_height
      next if !height
      h[n] = height
    }
    h
  end

  def set_non_channel_node_height(non_channel_nodes, dh, hh)
    non_channel_nodes.each {|n|
      next if n.get_node_height
      total_height = 0.0
      total_weight = 0.0
      hh.each {|n2, defined_height|
        distance = dh[n][n2]
        if distance == 0.0
          total_height = defined_height
          total_weight = 1.0
          break
        end
        weight = 1.0 / distance
        total_height += weight * defined_height
        total_weight += weight
      }
      height = total_height / total_weight
      n.set_node_height(height)
      #if %w[n102 n107].include? n.get_node_name then pp [n, height, total_height, total_weight, hh.map {|n2, h| [n2, h, dh[n][n2]] }]; end
    }
  end

  def set_channel_node_height(paths_hash)
    paths_hash.each {|n1, h|
      n1_height = n1.get_node_height
      h.each {|n2, paths|
        n2_height = n2.get_node_height
        paths.each {|path|
          distance = 0.0
          path.each {|pathelem|
            distance += pathelem.line.distance
          }
          d = 0.0
          path.each {|pathelem|
            break if pathelem.node.get_node_height
            d += pathelem.line.distance
            height = ((distance - d) * n1_height + d * n2_height) / distance
            pathelem.node.set_node_height height
          }
        }
      }
    }
  end

end
