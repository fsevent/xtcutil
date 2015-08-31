require 'json'

require 'xtcutil'

def main_graph(argv)
  argv.each {|arg|
    params = {}
    parsed = []
    open_xtc(arg) {|f|
      parse_io params, parsed, f
    }
    layout = Layout.new(parsed)
    pp layout.generate_graph
    #$stdout.puts JSON.pretty_generate(layout.generate_graph)
  }
end
