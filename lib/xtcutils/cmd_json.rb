require 'xtcutils/parser'

def main_json(argv)
  argv.each {|arg|
    open_xtc(arg) {|f|
      params = {}
      result = []
      def result.<<(arg)
        super
        pp arg
      end
      parse_io params, result, f
    }
  }
end
