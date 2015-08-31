require 'json'

require 'xtcutil/parser'

def main_parse_tree(argv)
  argv.each {|arg|
    params = {}
    parsed = []
    open_xtc(arg) {|f|
      parse_io params, parsed, f
    }
    $stdout.puts JSON.pretty_generate(parsed)
  }
end
