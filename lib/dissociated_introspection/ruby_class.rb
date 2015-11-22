module DissociatedIntrospection
  class RubyClass
    using ActiveSupport::Try

    def initialize(source: nil, ast: nil)
      @source = source
      @ast    = ast
      if source.nil? && ast.nil?
        raise ArgumentError.new "#{self.class.name} require either source or ast to be given as named arguments."
      end
    end

    def is_class?
      ast.type == :class
    end

    def class_name
      Unparser.unparse(find_class.to_a[0])
    end

    def parent_class_name
      Unparser.unparse(find_class.to_a[1])
    end

    def has_parent_class?
      return false if find_class.nil?
      find_class.to_a[1].try(:type) == :const
    end

    def change_class_name(class_name)
      reset_nodes
      nodes[0] = Parser::CurrentRuby.parse(class_name)
      new_ast  = ast.updated(nil, nodes, nil)
      self.class.new(ast: new_ast)
    end

    def modify_parent_class(parent_class)
      reset_nodes
      if has_parent_class?
        class_node    = find_class.to_a.dup
        class_node[1] = Parser::CurrentRuby.parse(parent_class.to_s)
        new_ast       = find_class.updated(nil, class_node, nil)
      else
        nodes[1] = nodes[0].updated(:const, [nil, parent_class.to_sym])
        new_ast  = ast.updated(nil, nodes, nil)
      end
      self.class.new(ast: new_ast)
    end

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

    def defs
      class_begin.children.select { |n| n.try(:type) == :def }.map{|n| Def.new(ast: n)}
    end

    def class_begin
      find_class.children.find{|n| n.try(:type) == :begin}
    end

    def to_ruby_str
      Unparser.unparse(ast)
    end

    def scrub_inner_classes
      self.class.new(ast: find_class.updated(find_class.type, class_begin.updated(class_begin.type, class_begin.children.reject { |n| n.try(:type) == :class })))
    end

    private

    attr_reader :source

    def find_class
      return ast if ast.try(:type) == :class
      ast.to_a.select { |n|n.try(:type) == :class }.first
    end

    def ast
      @ast ||= Parser::CurrentRuby.parse(source)
    end

    def nodes
      @nodes ||= ast.to_a.dup
    end

    def reset_nodes
      @nodes = nil
    end
  end
end

