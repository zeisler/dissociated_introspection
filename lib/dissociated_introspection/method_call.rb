module DissociatedIntrospection
  class Lambda
    attr_reader :ast

    def initialize(ast)
      @ast = ast
    end

    def type
      ast.type
    end

    def body
      RubyCode.build_from_ast(ast.to_a[2])
    end

    def arguments
      RubyCode.build_from_ast(ast.to_a[1])
    end
  end

  class MethodCall
    attr_reader :ruby_code

    def initialize(ruby_code)
      @ruby_code = ruby_code
    end

    def arguments
      ruby_code.ast.children[2..-1].map do |c|
        case c.type
        when :sym, :str
          c.to_a.first
        when :block
          Lambda.new(c)
        else
          c
        end
      end
    end

    def name
      ruby_code.ast.children[1]
    end

    def to_h
      { name: name, arguments: arguments }
    end

    class Argument
      attr_reader :ast

      def initialize(ast)
        @ast = ast
      end

      def type
        ast.type
      end

      def value
        case type
        when :block
          Block.new(ast.children)
        else
          ast.children[0]
        end
      end

      def to_h
        { type: type, value: value }
      end
    end
  end
end
