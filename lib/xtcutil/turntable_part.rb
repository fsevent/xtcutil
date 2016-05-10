# turntable_part.rb --- turntable part class
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
  class TurntablePart < Xtcutil::AbstractPart
    def lines
      return @lines if defined? @lines
      center = Vector[*@h[:pos]]
      radius = @h[:radius]
      ary = []
      @h[:segs].each {|seg|
        case seg[:type]
        when 'T'
          a = seg[:angle] * DEG_TO_RAD
          vec = Vector[Math.sin(a), Math.cos(a)]
          pos0 = center + vec * radius
          pos1 = center - vec * radius
          line = StraightLine.new(self, pos0, pos1)
          node_other_end = line.get_node(1)
          node_other_end.add_comment("T#{self.index}TP_A#{"%.3f" % seg[:angle]}")
          ary << line
        end
      }
      return @lines = ary
    end

    def each_track(&b)
      lines.each(&b)
    end

    def paths_ary
      return @paths_ary if defined? @paths_ary
      ary = []
      a = 0
      lines.each {|l|
        state = "a#{a += 1}"
        ary << [state, [[l]]]
      }
      return @paths_ary = ary
    end

    def each_state_paths
      paths_ary.each {|state, paths|
        yield state, paths, true, false
      }
    end

  end
end
