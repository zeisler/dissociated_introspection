module DissociatedIntrospection
  class EvalSandbox

    def initialize(file:, recording_parent: recording_parent_default, module_namespace: Module.new)
      @file             = file
      @recording_parent = recording_parent
      @module_namespace = module_namespace
    end


    def call
      module_namespace.module_eval(recording_parent.read, recording_parent.path)
      module_namespace.module_eval(file.read, file.path)
      module_namespace.const_get(module_namespace.constants.select{|c| c != :RecordingParent}.last)
    end

    def constants
      module_namespace.constants
    end

    private

    attr_reader :file, :recording_parent, :module_namespace

    def recording_parent_default
      File.new(File.join(File.dirname(__FILE__), "recording_parent.rb"))
    end

  end
end
