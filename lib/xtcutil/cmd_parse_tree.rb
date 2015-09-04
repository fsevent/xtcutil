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
