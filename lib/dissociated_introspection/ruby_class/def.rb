module DissociatedIntrospection
  class RubyClass
    class Def

      def initialize(ast:)
        @ast = ast
      end

      def name
        ast.children[0]
      end

      def arguments
        Unparser.unparse(ast.children[1])
      end

      def body
        Unparser.unparse(ast.children[2])
      end

      def to_ruby_str
        Unparser.unparse(ast)
      end

      private
      attr_reader :ast
    end
  end
end
