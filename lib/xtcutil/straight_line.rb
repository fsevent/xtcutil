# straight_line.rb --- straight line class
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
  class StraightLine < Xtcutil::AbstractLine
    def initialize(part, pos0, pos1)
      vec = pos0-pos1
      dir_angle0 = Math.atan2(vec[1], vec[0]) % (2 * Math::PI)
      dir_angle1 = (dir_angle0 + Math::PI) % (2 * Math::PI)
      super part, pos0, pos1, dir_angle0, dir_angle1
      @pos0 = pos0
      @pos1 = pos1
    end
    attr_reader :pos0, :pos1

    def distance
      (pos0 - pos1).r
    end

    def radius
      Float::INFINITY
    end

    def vector(tipindex)
      raise "unexpected pos index: #{i}" if i != 0 && i != 1
      return @vector if defined? @vector
      d = distance
      return @vector = [(@x1-@x0)/d, (@y1-@y0)/d]
    end

  end
end
