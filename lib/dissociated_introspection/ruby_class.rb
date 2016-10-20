module DissociatedIntrospection
  class RubyClass
    attr_reader :ruby_code
    using Try

    def initialize(ruby_code)
      @ruby_code = if ruby_code.is_a?(Hash) && ruby_code.has_key?(:source)
                     RubyCode.build_from_source(ruby_code[:source], parse_with_comments: ruby_code[:parse_with_comments])
                   elsif ruby_code.is_a?(Hash) && ruby_code.has_key?(:ast)
                     RubyCode.build_from_ast(ruby_code[:ast],
                                             comments: ruby_code.fetch(:comments, []))
                   else
                     ruby_code
                   end
    end

    def ast
      ruby_code.ast
    end

    def source
      ruby_code.source
    end

    def comments
      ruby_code.comments
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
      return false unless find_class
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

      self.class.new(RubyCode.build_from_ast(new_ast, comments: comments))
    end

    def defs
      class_begin.children.select { |n| n.try(:type) == :def }.map do |n|
        def_comments = comments.select do |comment|
          comment.location.last_line+1 == n.location.first_line
        end
        Def.new(RubyCode.build_from_ast(n, comments: def_comments))
      end
    end

    def class_begin
      find_class.children.find { |n| n.try(:type) == :begin } || find_class
    end

    def to_ruby_str
      source
    end

    def scrub_inner_classes
      self.class.new RubyCode.build_from_ast(scrub_inner_classes_ast,
                                             comments: comments)
    end

    def module_nesting
      ary = []
      m = ast
      while m
        if (m = depth_first_search(m, :module, :class))
          name = m.to_a[0].to_a[1]
          ary << name unless name.nil?
          m = m.to_a[1]
        end
      end
      ary
    end

    private

    def scrub_inner_classes_ast
      find_class.updated(find_class.type,
                         class_begin.updated(class_begin.type,
                                             class_begin.children.reject { |n| n.try(:type) == :class }))
    end

    def find_class
      depth_first_search(ast, :class)
    end

    def depth_first_search(node, target, stop=nil)
      return false unless node.is_a?(Parser::AST::Node)
      return node if node.type == target
      return false if stop && node.type == stop
      if (children = node.children)
        children.each do |kid|
          v = depth_first_search(kid, target, stop)
          return v if v.is_a?(Parser::AST::Node)
        end
      end
      return false
    end

    def nodes
      @nodes ||= ast.to_a.dup
    end

    def reset_nodes
      @nodes = nil
    end
  end
end

