require 'json'

require 'xtcutils/parser'

def main_json(argv)
  argv.each {|arg|
    params = {}
    result = []
    open_xtc(arg) {|f|
      parse_io params, result, f
    }
    $stdout.puts JSON.pretty_generate(result)
  }
end
