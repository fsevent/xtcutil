require 'matrix'

DEG_TO_RAD = Math::PI / 180

def matrix_rotate(rad)
  c = Math.cos(rad)
  s = Math.sin(rad)
  Matrix[
    [c, -s, 0.0],
    [s, c, 0.0],
    [0.0, 0.0, 1]
  ]
end

def matrix_translate(x, y)
  Matrix[
    [1.0, 0.0, x],
    [0.0, 1.0, y],
    [0.0, 0.0, 1.0]
  ]
end

def affine_transform(mat, x, y)
  x, y, _ = (mat * Vector[x, y, 1.0]).to_a
  return x, y
end

def rotate_angle(mat, rad)
  c = mat[0,0]
  s = mat[1,0]
  rad + Math.atan2(s, c)
end

