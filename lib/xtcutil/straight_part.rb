# straight_part.rb --- straight part class
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
  class StraightPart < Xtcutil::AbstractPart
    def lines
      return @lines if defined? @lines
      @pos0 = Vector[*@h[:segs][0][:pos]]
      @pos1 = Vector[*@h[:segs][1][:pos]]
      ary = [StraightLine.new(self, @pos0, @pos1)]
      return @lines = ary
    end

    def each_track(&b)
      lines.each(&b)
    end

    def paths_ary
      return @paths_ary if defined? @paths_ary
      return @paths_ary = [[lines]]
    end

    def each_state_paths
      yield nil, paths_ary[0], true, true
    end

  end
end
