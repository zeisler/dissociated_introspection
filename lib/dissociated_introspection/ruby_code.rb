module DissociatedIntrospection
  class RubyCode

    # @param [String] source
    # @param [true, false] parse_with_comments
    # @return [DissociatedIntrospection::RubyCode]
    def self.build_from_source(source, parse_with_comments: false)
      ast, comments = create_ast(parse_with_comments, source)
      new(source:              source,
          ast:                 ast,
          comments:            comments)
    end

    # @param [Ast] ast
    # @param [Array] comments
    # @return [DissociatedIntrospection::RubyCode]
    def self.build_from_ast(ast, comments: [])
      new(source:   nil,
          ast:      ast,
          comments: comments
      )
    end

    # @private
    def self.parse_source_method(parse_with_comments)
      parse_with_comments ? :parse_with_comments : :parse
    end

    # @private
    def self.create_ast(parse_with_comments, source)
      a = Parser::CurrentRuby.public_send(self.parse_source_method(parse_with_comments), source)
      if parse_with_comments
        [a[0], a[1]]
      else
        [a, []]
      end
    end

    attr_reader :ast, :comments
    #@private
    def initialize(source:, ast:, comments:)
      @source   = source
      @ast      = ast
      @comments = comments
    end

    def comments?
      !comments.empty?
    end

    # @return [String]
    def source
      @source = @source.nil? ? source_from_ast : @source
    end

    # @return [String]
    def source_from_ast
      Unparser.unparse(ast, comments)
    end
  end
end
