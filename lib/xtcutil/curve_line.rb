# curve_line.rb --- curved line class
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
  class CurveLine < Xtcutil::AbstractLine
    def initialize(part, center, radius, a0, a1)
      raise "curveline constraint violation: #{a0} > #{a1} (should be a0 <= a1)" if a0 > a1
      pos0 = Vector[
        center[0] + radius * Math.cos(a0),
        center[1] + radius * Math.sin(a0)
      ].freeze
      pos1 = Vector[
        center[0] + radius * Math.cos(a1),
        center[1] + radius * Math.sin(a1)
      ].freeze
      dir_angle0 = (a0 - Math::PI/2) % (2 * Math::PI)
      dir_angle1 = (a1 + Math::PI/2) % (2 * Math::PI)
      super part, pos0, pos1, dir_angle0, dir_angle1
      @center = center
      @radius = radius
      @a0 = a0
      @a1 = a1
    end
    attr_reader :center, :radius, :a0, :a1

    def distance
      @radius * (@a1 - @a0)
    end

    def vector(tipindex)
      raise "unexpected pos index: #{i}" if i != 0 && i != 1
      return @vectors[tipindex] if defined? @vectors
      @vectors = [
        [
          -Math.sin(@a0),
          Math.cos(@a0),
        ],
        [
          -Math.sin(@a1),
          Math.cos(@a1),
        ],
      ]
      return @vectors[tipindex]
    end

  end
end
