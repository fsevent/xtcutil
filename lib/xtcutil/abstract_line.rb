# abstract_line.rb --- abstract class for lines.
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
  class AbstractLine
    def initialize(part, pos0, pos1, dir_angle0, dir_angle1)
      @part = part
      @pos0 = pos0
      @pos1 = pos1
      @dir_angle0 = dir_angle0
      @dir_angle1 = dir_angle1
      @line_name = nil
      n0 = Node.new
      n1 = Node.new
      n0.add_comment("T#{part.index}")
      n1.add_comment("T#{part.index}")
      n0.add_line(dir_angle0, 0, self)
      n1.add_line(dir_angle1, 1, self)
      @nodes = [n0, n1]
    end
    attr_reader :part, :pos0, :pos1, :dir_angle0, :dir_angle1

    def pretty_print_instance_variables
      instance_variables.sort - [:@part]
    end

    def pretty_print(q)
      q.pp_object(self)
    end

    alias inspect pretty_print_inspect

    def get_pos(i)
      raise "unexpected tip index: #{i}" if i != 0 && i != 1
      if i == 0
        @pos0
      else
        @pos1
      end
    end

    def set_line_name(line_name)
      raise "line name already set" if @line_name
      @line_name = line_name
    end

    def get_line_name
      @line_name
    end

    def fetch_line_name
      raise "line name not set" if !@line_name
      @line_name
    end

    def get_node(i)
      raise "unexpected tip index: #{i}" if i != 0 && i != 1
      node = @nodes[i]
      @nodes[i] = node.unified_node
    end

    def fetch_node(i)
      get_node(i)
    end

    def get_dir_angle(i)
      raise "unexpected tip index: #{i}" if i != 0 && i != 1
      if i == 0
        dir_angle0
      else # i == 1
        dir_angle1
      end
    end
  end
end
