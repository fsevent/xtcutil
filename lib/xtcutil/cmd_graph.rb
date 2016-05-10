# cmd_graph.rb --- "graph" subcommand implementation
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
      eps = n.get_list_attr(:ep)
      eps.each {|ep1_part_index, ep1_num, ep1_type|
        eps.each {|ep2_part_index, ep2_num, ep2_type|
          next if ep1_part_index == ep2_part_index
          part1 = layout.get_part(ep1_part_index)
          part2 = layout.get_part(ep2_part_index)
          part1.each_state_paths {|state1, paths1|
            state1 ||= ''
            paths1.each {|path1|
              startindex_ary1 = layout.startindex_for_path(path1)
              if n == path1[0].get_node(startindex_ary1[0])
                startindex1 = 1-startindex_ary1[0]
                edge1 = path1[0].get_line_name
                endindex1 = startindex_ary1[0]
              elsif n == path1[-1].get_node(1-startindex_ary1[-1])
                startindex1 = startindex_ary1[-1]
                edge1 = path1[-1].get_line_name
                endindex1 = 1-startindex_ary1[-1]
              else
                next
              end
              part2.each_state_paths {|state2, paths2|
                state2 ||= ''
                paths2.each {|path2|
                  startindex_ary2 = layout.startindex_for_path(path2)
                  if n == path2[0].get_node(startindex_ary2[0])
                    startindex2 = startindex_ary2[0]
                    edge2 = path2[0].get_line_name
                    endindex2 = 1-startindex_ary2[0]
                  elsif n == path2[-1].get_node(1-startindex_ary2[-1])
                    startindex2 = 1-startindex_ary2[-1]
                    edge2 = path2[-1].get_line_name
                    endindex2 = startindex_ary2[-1]
                  else
                    next
                  end
                  connection_hash = {
                    type:"inter-part-connection",
                    node:n.get_node_name,
                    part1:"T#{ep1_part_index}",
                    part2:"T#{ep2_part_index}",
                    state1:state1,
                    state2:state2,
                    startindex1:startindex1,
                    edge1:edge1,
                    endindex1:endindex1,
                    startindex2:startindex2,
                    edge2:edge2,
                    endindex2:endindex2,
                  }
                  json_data << connection_hash
                }
              }
            }
          }
        }
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
      part.each_state_paths {|state, paths|
        paths.each {|path|
          startindex_ary = layout.startindex_for_path(path)
          startindex_linename_ary = startindex_ary.zip(path).map {|i, line| [i, line.get_line_name] }
          state ||= ''
          1.upto(path.length-1) {|j|
            connection_hash = {
              type:"intra-part-connection",
              node:path[j-1].get_node(1-startindex_ary[j-1]).get_node_name,
              part:"T#{part.index}",
              state:state,
              startindex1:startindex_ary[j-1],
              edge1:path[j-1].get_line_name,
              endindex1:1-startindex_ary[j-1],
              startindex2:startindex_ary[j],
              edge2:path[j].get_line_name,
              endindex2:1-startindex_ary[j],
            }
            json_data << connection_hash
            # reverse path is always available until we support spring point.
            connection_hash = {
              type:"intra-part-connection",
              node:path[j].get_node(startindex_ary[j]).get_node_name,
              part:"T#{part.index}",
              state:state,
              startindex1:1-startindex_ary[j],
              edge1:path[j].get_line_name,
              endindex1:startindex_ary[j],
              startindex2:1-startindex_ary[j-1],
              edge2:path[j-1].get_line_name,
              endindex2:startindex_ary[j-1],
            }
            json_data << connection_hash
          }
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
