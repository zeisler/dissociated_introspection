module DissociatedIntrospection
  class RubyClass
    attr_reader :ruby_code
    extend Forwardable
    using Try

    # @param [DissociatedIntrospection::RubyCode, String, Parse::AST, Hash{source: String, parse_with_comments: [Boolean]}] ruby_code
    def initialize(ruby_code)
      @ruby_code = if ruby_code.is_a?(Hash) && ruby_code.key?(:source)
                     RubyCode.build_from_source(
                       ruby_code[:source],
                       parse_with_comments: ruby_code[:parse_with_comments]
                     )
                   elsif ruby_code.is_a?(Hash) && ruby_code.key?(:ast)
                     RubyCode.build_from_ast(
                       ruby_code[:ast],
                       comments: ruby_code.fetch(:comments, [])
                     )
                   else
                     ruby_code
                   end
    end

    def_delegators :ruby_code, :ast, :source, :comments

    def class?
      ast.type == :class
    end

    # @return [String]
    def class_name
      Unparser.unparse(find_class.to_a[0])
    end

    # @return [String]
    def parent_class_name
      Unparser.unparse(find_class.to_a[1])
    end

    def parent_class?
      return false unless find_class
      find_class.to_a[1].try(:type) == :const
    end

    # @return [DissociatedIntrospection::RubyClass]
    def change_class_name(class_name)
      nodes    = ast.to_a.dup
      nodes[0] = Parser::CurrentRuby.parse(class_name)
      new_ast  = ast.updated(nil, nodes, nil)
      self.class.new(ast: new_ast)
    end

    # @return [DissociatedIntrospection::RubyClass]
    def modify_parent_class(parent_class)
      if parent_class?
        class_node    = find_class.to_a.dup
        class_node[1] = Parser::CurrentRuby.parse(parent_class.to_s)
        new_ast       = find_class.updated(nil, class_node, nil)
      else
        nodes    = ast.to_a.dup
        nodes[1] = nodes[0].updated(:const, [nil, parent_class.to_sym])
        new_ast  = ast.updated(nil, nodes, nil)
      end

      self.class.new(RubyCode.build_from_ast(new_ast, comments: comments))
    end

    # @return [Array<DissociatedIntrospection::RubyClass::Def>]
    def defs
      class_begin.children.select { |n| n.try(:type) == :def }.map(&method(:create_def))
    end

    # @return [Array<DissociatedIntrospection::RubyClass::Def>]
    def class_defs
      ns = class_begin.children.select { |n| :defs == n.try(:type) }.map do |n|
        create_def(n.updated(:def, n.children[1..-1]))
      end
      ns2 = class_begin.children.select { |n| :sclass == n.try(:type) }.flat_map do |n|
        next create_def(n.children[1]) if n.children[1].type == :def
        n.children[1].children.select { |n| n.try(:type) == :def }.map(&method(:create_def))
      end
      [*ns, *ns2]
    end

    # @private
    def inspect_methods(type=:instance_methods)
      public_send(if type == :instance_methods
                    :defs
                  elsif [:methods, :class_methods].include?(type)
                    :class_defs
                  end)
    end

    # @return [RubyClass]
    def scrub_inner_classes
      self.class.new RubyCode.build_from_ast(
        scrub_inner_classes_ast,
        comments: comments
      )
    end

    # @return [Array[Symbol]]
    def module_nesting
      ary = []
      m   = ast
      while m
        next unless (m = depth_first_search(m, :module, :class))
        name = m.to_a[0].to_a[1]
        ary << name unless name.nil?
        m = m.to_a[1]
      end
      ary
    end

    # @return [Array<DissociatedIntrospection::RubyCode>]
    def defined_nested_modules
      class_begin.children.select { |n| n.try(:type) == :module }.map do |m|
        RubyCode.build_from_ast(
          m
        )
      end
    end

    # @return [Array<DissociatedIntrospection::RubyCode>]
    def defined_nested_classes
      class_begin.children.select { |n| n.try(:type) == :class }.map do |m|
        RubyCode.build_from_ast(
          m
        )
      end
    end

    # @return [DissociatedIntrospection::MethodCall]
    def class_method_calls
      class_begin.children.select { |n| n.try(:type) == :send }.map do |ast|
        MethodCall.new(RubyCode.build_from_ast(ast))
      end
    end

    # @return [AST]
    def class_begin
      find_class.children.find { |n| n.try(:type) == :begin } || find_class
    end

    private

    def create_def(n)
      def_comments = comments.select do |comment|
        comment.location.last_line+1 == n.location.first_line
      end
      Def.new(RubyCode.build_from_ast(n, comments: def_comments))
    end

    def scrub_inner_classes_ast
      find_class.updated(find_class.type,
                         class_begin.updated(class_begin.type,
                                             class_begin.children.reject { |n| n.try(:type) == :class }))
    end

    def find_class
      depth_first_search(ast, :class) || ast
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
      false
    end
  end
end

