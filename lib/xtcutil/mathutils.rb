# mathutils.rb --- mathematical utilities
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

require 'matrix'

module Xtcutil
  DEG_TO_RAD = Math::PI / 180

  module MathUtil

    def matrix_rotate(rad)
      c = Math.cos(rad)
      s = Math.sin(rad)
      Matrix[
        [c, -s, 0.0],
        [s, c, 0.0],
        [0.0, 0.0, 1]
      ]
    end

    def matrix_translate(vec)
      Matrix[
        [1.0, 0.0, vec[0]],
        [0.0, 1.0, vec[1]],
        [0.0, 0.0, 1.0]
      ]
    end

    def affine_transform(mat, pos)
      x, y, _ = (mat * Vector[pos[0], pos[1], 1.0]).to_a
      return Vector[x, y]
    end

    def rotate_angle(mat, rad)
      c = mat[0,0]
      s = mat[1,0]
      rad + Math.atan2(s, c)
    end
  end
end
