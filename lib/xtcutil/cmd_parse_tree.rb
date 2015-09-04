require 'json'

require 'xtcutil/parser'

module Xtcutil
  class CmdParseTree
    def main_parse_tree(argv)
      argv.each {|arg|
        params = {}
        parsed = []
        Xtcutil::Parser.open_xtc(arg) {|f|
          Xtcutil::Parser.parse_io params, parsed, f
        }
        $stdout.puts JSON.pretty_generate(parsed)
      }
    end
  end
end
