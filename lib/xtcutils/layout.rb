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
    setup_other_node(node_ary)
    node_ary = clean_nodes(node_ary)
    setup_node_name(node_ary)
    setup_elevation(node_ary)
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
          node.set_attr(:defined_height, true)
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

  def setup_other_node(node_ary)
    each_part {|part|
      part.each_track {|line|
        0.upto(1) {|i|
          if !line.get_node(i)
            node = Node.new
            line.set_node(i, node)
            node_ary << node
          end
        }
      }
    }
  end

  def clean_nodes(node_ary)
    node_ary = node_ary.reject {|node| !node.equal?(node.unified_node) }
    node_ary.each {|node|
      node.each_line {|posindex, line|
        n0 = line.fetch_node(0)
        n1 = line.fetch_node(1)
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

  PathElem = Struct.new("PathElem", :posindex1, :line, :posindex2, :node)

  def each_elevation_computation_area(n0)
    n0.each_line {|posindex_a1, line_a|
      paths_hash = {}
      posindex_a2 = 1-posindex_a1
      n1 = line_a.get_node(posindex_a2)
      next if n1.get_node_height
      visited = { n0 => true, n1 => true }
      q = []
      if n1.num_lines == 2
        q.push [n0, [PathElem[posindex_a1, line_a, posindex_a2, n1]], n1]
      else
        paths_hash[n0] ||= {}
        paths_hash[n0][n1] ||= []
        paths_hash[n0][n1] << [PathElem[posindex_a1, line_a, posindex_a2, n1]]
        q.push [n1, [], n1]
      end
      until q.empty?
        n1, path, n2 = q.pop
        n2.each_line {|posindex_b1, line_b|
          posindex_b2 = 1-posindex_b1
          n3 = line_b.get_node(posindex_b2)
          next if !path.empty? && path.last.line == line_b
          path3 = path + [PathElem[posindex_b1, line_b, posindex_b2, n3]]
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
