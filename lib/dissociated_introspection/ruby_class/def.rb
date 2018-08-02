module DissociatedIntrospection
  class RubyClass
    class Def
      # @param [DissociatedIntrospection::RubyClass] ruby_code
      def initialize(ruby_code)
        @ruby_code = ruby_code
      end

      # @return [Symbol, NilClass]
      def name
        ruby_code.ast.children[0]
      end

      # @return [DissociatedIntrospection::RubyClass]
      def arguments
        RubyCode.build_from_ast(ruby_code.ast.children[1])
      end

      # @return [DissociatedIntrospection::RubyClass]
      def body
        RubyCode.build_from_ast(ruby_code.ast.children[2])
      end

      # @return [String]
      def source
        ruby_code.source
      end

      def to_s
        ruby_code.source
      end

      # @return [Parser::AST]
      def ast
        ruby_code.ast
      end

      # @return [DissociatedIntrospection::RubyClass]
      attr_reader :ruby_code
    end
  end
end
