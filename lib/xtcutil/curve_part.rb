# curve_part.rb --- curved part class
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
  class CurvePart < Xtcutil::AbstractPart
    def circle?
      a0 = @h[:segs][0][:angle]
      a1 = @h[:segs][1][:angle]
      a0 == 270.0 && a1 == 90.0
    end

    def lines
      return @lines if defined? @lines
      center = Vector[*@h[:pos]]
      radius = @h[:radius]
      a0 = @h[:segs][1][:angle]
      a1 = @h[:segs][0][:angle]
      if a0 == 90 && a1 == 270
        a0 = 0.0
        a1 = 2*Math::PI
      else
        a0 = (180-a0) * DEG_TO_RAD
        a1 = (-a1) * DEG_TO_RAD
      end
      while a0 > a1
        a1 += 2*Math::PI
      end
      ary = [CurveLine.new(self, center, radius, a0, a1)]
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
