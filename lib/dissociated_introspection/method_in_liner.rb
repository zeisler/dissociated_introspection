module DissociatedIntrospection
  class MethodInLiner
    attr_reader :defs, :ruby_code
    # @param [Array<DissociatedIntrospection::RubyClass::Def>] defs
    # @param [DissociatedIntrospection::RubyCode] ruby_code
    def initialize(ruby_code, defs:)
      @defs      = defs
      @ruby_code = ruby_code
    end

    # @return [DissociatedIntrospection::RubyCode]
    def in_line
      rewriter      = InLiner.new
      rewriter.defs = defs
      result        = rewriter.process(ruby_code.ast)
      RubyCode.build_from_ast(result)
    end

    class InLiner < Parser::TreeRewriter
      attr_accessor :defs

      def on_send(node)
        called_on, method_name, *args = *node
        # TODO: Deal with args by replacing lvar with passed objects
        return super unless args.empty? && called_on_self?(called_on)
        called_method = called_method(method_name)
        return super unless called_method
        node.updated(called_method.body.ast.type, called_method.body.ast.children)
      end

      def called_on_self?(called_on)
        called_on.nil? || called_on.type == :self
      end

      def called_method(method_name)
        defs.detect { |_def| _def.name == method_name }
      end
    end
  end
end
