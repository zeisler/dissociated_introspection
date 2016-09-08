module DissociatedIntrospection
  class RubyClass
    class Def

      def initialize(ruby_code)
        @ruby_code = ruby_code
      end

      def name
        ruby_code.ast.children[0]
      end

      def arguments
        Unparser.unparse(ruby_code.ast.children[1])
      end

      def body
        Unparser.unparse(ruby_code.ast.children[2])
      end

      def to_ruby_str
        ruby_code.to_ruby_str
      end

      private
      attr_reader :ruby_code
    end
  end
end
