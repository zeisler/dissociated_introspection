module DissociatedIntrospection
  class EvalSandbox

    def initialize(file:)
      @file = file
    end


    def call
      module_namespace.module_eval(file.read, file.path)
      module_namespace.const_get(module_namespace.constants.last)
    end

    private

    attr_reader :file

    def module_namespace
      @module ||= Module.new
    end

  end
end