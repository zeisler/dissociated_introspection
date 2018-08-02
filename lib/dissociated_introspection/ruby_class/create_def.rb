module DissociatedIntrospection
  class RubyClass
    class CreateDef
      attr_reader :ast, :comments

      def initialize(ast, comments)
        @ast      = ast
        @comments = comments
      end

      def create
        def_comments = comments.select do |comment|
          comment.location.last_line + 1 == ast.location.first_line
        end
        Def.new(RubyCode.build_from_ast(ast, comments: def_comments))
      end
    end
  end
end
