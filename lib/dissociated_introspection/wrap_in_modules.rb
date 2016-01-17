module DissociatedIntrospection
  class WrapInModules
    # @param [DissociatedIntrospection::RubyCode] ruby_code
    def initialize(ruby_code:)
      @ruby_code = ruby_code
    end

    # @param [String] modules
    # @return [DissociatedIntrospection::RubyCode]
    def call(modules:)
      return ruby_code if modules.nil? || modules.empty?
      wrap_in_modules(modules)
    end

    private

    attr_reader :ruby_code

    def wrap_in_modules(modules)
      ruby_string = ruby_code.source_from_ast
      modules.split("::").reverse.each do |module_name|
        ruby_string = wrap_module(module_name, ruby_string)
      end
      RubyCode.build_from_source(ruby_string, parse_with_comments: ruby_code.comments?)
    end

    def wrap_module(module_name, ruby_string)
      <<-RUBY
    module #{module_name}
      #{ruby_string}
    end
      RUBY
    end
  end
end
