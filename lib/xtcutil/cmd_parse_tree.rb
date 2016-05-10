# cmd_parse_tree --- "parse-tree" subcommand implementation
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

require 'json'

require 'xtcutil/parser'

module Xtcutil
  module_function

  def parse_tree_main(argv)
    argv.each {|arg|
      parsed = Xtcutil::Parser.parse_file(arg)
      $stdout.puts JSON.pretty_generate(parsed)
    }
  end
end
