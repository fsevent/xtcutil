require 'xtcutils/parser'

def main_json(argv)
  argv.each {|arg|
    enc = Encoding.find("locale")
    if !File.read(arg, external_endoding:enc).valid_encoding?
      enc = Encoding::ISO_8859_1
    end
    File.open(arg, :external_encoding=>enc) {|f|
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
