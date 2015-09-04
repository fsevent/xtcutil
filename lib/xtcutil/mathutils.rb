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
