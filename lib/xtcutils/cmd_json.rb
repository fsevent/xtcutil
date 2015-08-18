require 'json'

require 'xtcutils/parser'

def main_json(argv)
  argv.each {|arg|
    params = {}
    parsed = []
    open_xtc(arg) {|f|
      parse_io params, parsed, f
    }
    $stdout.puts JSON.pretty_generate(parsed)
  }
end
