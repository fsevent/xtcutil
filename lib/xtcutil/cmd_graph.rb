require 'json'

require 'xtcutil'

module Xtcutil
  module_function

  def graph_to_json_data(layout)
    graph = layout.generate_graph
    line_visited = {}
    json_data = []
    graph.each {|n|
      pos = n.mean_pos.to_a
      pos = [nil, nil] if !pos
      pos << n.get_node_height
      node_hash = {
        type:"node",
        name:n.get_node_name,
        degree:n.num_lines,
        pos:pos,
        max_gap:n.max_gap, # max_gap should be small.
      }
      if 0 < n.count_list_attr(:comments)
        node_hash[:comments] = n.get_list_attr(:comments)
      end
      json_data << node_hash
      n.each_line {|tipindex, line|
        next if line_visited.has_key?(line)
        line_visited[line] = true
        edge_hash = {
          type:"edge",
          name:line.get_line_name,
          part:"T#{line.part.index}",
          angle0:line.dir_angle0,
          pos0:line.pos0.to_a,
          node0:line.get_node(0).get_node_name,
          node1:line.get_node(1).get_node_name,
          pos1:line.pos1.to_a,
          angle1:line.dir_angle1,
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
            center:line.center.to_a,
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
      numstates = 0
      part.each_state_paths {|state, paths| numstates += 1 }
      part_hash = {
        type:"part",
        part:"T#{part.index}",
        numstates:numstates,
      }
      json_data << part_hash
      part.each_state_paths {|state, paths|
        paths.each {|path|
          startindex_ary = layout.startindex_for_path(path)
          startindex_linename_ary = startindex_ary.zip(path).map {|i, line| [i, line.get_line_name] }
          state ||= ''
          path_hash = {
            type:"path",
            part:"T#{part.index}",
            state:state,
            edges:startindex_linename_ary,
          }
          json_data << path_hash
          # reverse path is always available until we support spring point.
          path_hash = path_hash.dup
          path_hash[:edges] = path_hash[:edges].map {|i, line_name| [1-i, line_name] }.reverse
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

  def graph_main(argv)
    argv.each {|arg|
      parsed = Xtcutil::Parser.parse_file(arg)
      layout = Layout.new(parsed)
      json_data = graph_to_json_data(layout)
      graph_output_json(json_data)
    }
  end
end
