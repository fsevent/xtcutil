# abstract_part --- abstract class for parts
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

module Xtcutil
  class AbstractPart
    def initialize(layout, h)
      @layout = layout
      @h = h
      @endpoint_node = {}
      @endpoint_node.compare_by_identity
    end

    def pretty_print_instance_variables
      instance_variables.sort - [:@layout]
    end

    def pretty_print(q)
      q.pp_object(self)
    end

    alias inspect pretty_print_inspect

    def index
      @h[:index].to_int
    end

    def each_seg(&b)
      segs = @h[:segs]
      segs.each(&b)
    end

    def nearest_endpoint_internal(pos1, types, from_index, from_ep_num)
      result_ep = nil
      result_distance = nil
      ep_num = 0
      each_seg {|seg|
        next if seg[:type] != 'E' && seg[:type] != 'T'
        ep_num += 1
        next unless types.include? seg[:type]
        if from_index
          # don't connect to unexpected endpoint.
          next if from_index != seg[:index]
          # don't connect to itself.
          next if from_index == self.index && from_ep_num == ep_num
        end
        pos2 = Vector[*seg[:pos]]
        distance = (pos1 - pos2).r
        if !result_ep
          result_ep = seg
          result_distance = distance
        else
          if distance < result_distance
            result_ep = seg
            result_distance = distance
          end
        end
      }
      result_ep
    end

    def nearest_connected_endpoint(pos1)
      nearest_endpoint_internal(pos1, %w[T], nil, nil)
    end

    def nearest_endpoint(pos1)
      nearest_endpoint_internal(pos1, %w[T E], nil, nil)
    end

    def nearest_connected_endpoint_from(pos1, index, ep_num)
      nearest_endpoint_internal(pos1, %w[T], index, ep_num)
    end

    def set_endpoint_node(ep, endpoint_node)
      if @endpoint_node[ep]
        raise "endpoint node already set"
      end
      @endpoint_node[ep] = endpoint_node
    end

    def fetch_endpoint_node(ep)
      node = @endpoint_node.fetch(ep)
      @endpoint_node[ep] = node.unified_node
    end

    def get_endpoint_node(ep)
      node = @endpoint_node[ep]
      if node
        @endpoint_node[ep] = node.unified_node
      else
        nil
      end
    end

    def each_path
      each_state_paths {|name, paths, has_start_ep, has_end_ep|
        paths.each {|path|
          yield path, has_start_ep, has_end_ep
        }
      }
    end

  end
end
