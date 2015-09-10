module DissociatedIntrospection
  class EvalSandbox

    def initialize(file:, recording_parent: recording_parent_default)
      @file             = file
      @recording_parent = recording_parent
    end


    def call
      module_namespace.module_eval(recording_parent.read, recording_parent.path)
      module_namespace.module_eval(file.read, file.path)
      module_namespace.const_get(module_namespace.constants.last)
    end

    def constants
      module_namespace.constants
    end

    private

    attr_reader :file, :recording_parent

    def module_namespace
      @module ||= Module.new
    end

    def recording_parent_default
      File.new(File.join(File.dirname(__FILE__), "recording_parent.rb"))
    end

  end
end