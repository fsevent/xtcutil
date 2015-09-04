require 'json'

require 'xtcutil'

module Xtcutil
  class CmdGraph
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
        lines = []
        n.each_line_with_angle {|dir_angle, tipindex, line|
          lines << [dir_angle, tipindex, line]
        }
        if lines.empty?
          node_hash[:edges0] = []
          node_hash[:edges1] = []
        elsif lines.length == 1
          node_hash[:edges0] = [lines[0][1], lines[0][2].get_line_name]
          node_hash[:edges1] = []
        elsif lines.length == 2
          node_hash[:edges0] = [lines[0][1], lines[0][2].get_line_name]
          node_hash[:edges1] = [lines[0][1], lines[1][2].get_line_name]
        else # lines.length > 2
          lines = lines.sort_by {|dir_angle, tipindex, line| dir_angle }
          indexes = (0...lines.length).map {|i| [i] }
          while 2 < indexes.length
            min_j = (0...indexes.length).min_by {|j|
              is = indexes[j]
              i0 = is[-1]
              i1 = (i0 + 1) % lines.length
              angle_extent = lines[i1][0] - lines[i0][0]
              angle_extent += 2 * Math::PI if angle_extent < 0
              angle_extent
            }
            if min_j + 1 < indexes.length
              indexes[min_j].concat indexes.delete_at(min_j+1)
            else
              is1 = indexes.shift
              indexes.last.concat is1
            end
          end
          is0, is1 = indexes
          node_hash[:edges0] = is0.map {|i| [lines[i][1], lines[i][2].get_line_name] }
          node_hash[:edges1] = is1.map {|i| [lines[i][1], lines[i][2].get_line_name] }
          angle_extent0 = lines[is0[-1]][0] - lines[is0[0]][0]
          angle_extent0 += 2 * Math::PI if angle_extent0 < 0
          angle_extent1 = lines[is1[-1]][0] - lines[is1[0]][0]
          angle_extent1 += 2 * Math::PI if angle_extent1 < 0
          # angle_extent should be small.
          node_hash[:angle_extent0] = angle_extent0
          node_hash[:angle_extent1] = angle_extent1
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

    def main_graph(argv)
      argv.each {|arg|
        params = {}
        parsed = []
        Xtcutil::Parser.open_xtc(arg) {|f|
          Xtcutil::Parser.parse_io params, parsed, f
        }
        layout = Layout.new(parsed)
        json_data = graph_to_json_data(layout)
        graph_output_json(json_data)
      }
    end
  end
end
