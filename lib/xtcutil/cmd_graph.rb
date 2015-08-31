require 'json'

require 'xtcutil'

def graph_to_json_data(layout)
  graph = layout.generate_graph
  line_visited = {}
  json_data = []
  graph.each {|n|
    pos = n.mean_pos
    pos = [nil, nil] if !pos
    pos << n.get_node_height
    node_hash = {
      type:"node",
      name:n.get_node_name,
      degree:n.num_lines,
      pos:pos,
      #max_gap:n.max_gap,
      comments:n.comments,
    }
    json_data << node_hash
    n.each_line {|posindex, line|
      next if line_visited.has_key?(line)
      line_visited[line] = true
      edge_hash = {
        type:"edge",
        name:line.get_line_name,
        node0:line.get_node(0).get_node_name,
        node1:line.get_node(1).get_node_name,
        pos0:line.pos0,
        pos1:line.pos1,
        distance:line.distance,
      }
      case line
      when StraightLine
        line_hash = {
          type:"straightline",
          name:line.get_line_name,
        }
      when CurveLine
        line_hash = {
          type:"curveline",
          name:line.get_line_name,
          center:[line.cx, line.cy],
          radius:line.radius,
          angle0:line.a0,
          angle1:line.a1,
        }
      else
        line_hash = nil
      end
      json_data << edge_hash
      json_data << line_hash if line_hash
    }
  }
  layout.each_part {|part|
    part.each_state_paths {|state, paths|
      part_hash = {
        type:"part",
        part:"T#{part.index}",
        numstates:paths.length,
      }
      json_data << part_hash
      paths.each {|path|
        startindex_ary = layout.startindex_for_path(path)
        state ||= ''
        path_hash = {
          type:"path",
          part:"T#{part.index}",
          state:state,
          edges:path.map {|line| line.get_line_name},
        }
        json_data << path_hash
      }
    }
  }
  json_data
end

def graph_output_json(json_data)
  print "["
  sep = "\n"
  json_data.each {|h|
    print sep
    print JSON.generate(h)
    sep = ",\n"
  }
  print "\n]\n"
end

def main_graph(argv)
  argv.each {|arg|
    params = {}
    parsed = []
    open_xtc(arg) {|f|
      parse_io params, parsed, f
    }
    layout = Layout.new(parsed)
    json_data = graph_to_json_data(layout)
    graph_output_json(json_data)
  }
end
