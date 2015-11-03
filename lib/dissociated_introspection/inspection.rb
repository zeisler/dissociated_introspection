require 'ostruct'

module DissociatedIntrospection
  class Inspection

    def initialize(file:, parent_class_replacement: :RecordingParent)
      @file                     = file
      @parent_class_replacement = parent_class_replacement
    end

    def get_class
      @get_class ||= _get_class
    end

    def class_macros(type=nil)
      return get_class.__missing_class_macros__ if type.nil?
    end

    def extended_modules
      find_class_macro_by_type(:extend) { |a| add_method_name_wo_parent a.first }
    end

    def included_modules
      find_class_macro_by_type(:include) { |a| add_method_name_wo_parent a.first }
    end

    def prepend_modules
      find_class_macro_by_type(:prepend) { |a| add_method_name_wo_parent a.first }
    end

    def missing_constants
      get_class.__missing_constants__
    end

    def parsed_source
      @parsed_source ||= RubyClass.new(source: file.read)
    end

    def sandbox_module
      @sandbox_module ||= Module.new
    end

    private

    def add_method_name_wo_parent(_module)
      def _module.referenced_name
        n = name.split("::")
        return n[2..-1].join("::") if n.first =~ /#<Module:.*>/
        return n[1..-1].join("::")
      end
      _module
    end

    def find_class_macro_by_type(type)
      get_class.__missing_class_macros__.select { |h| h.keys.first == type }.map { |h| yield(h.values.first.first) }
    end

    def _get_class
      modified_class_source = parsed_source.modify_parent_class(parent_class_replacement)
      load_sandbox(OpenStruct.new(read: modified_class_source.to_ruby_str, path: file.path))
    end

    def load_sandbox(file)
      @klass ||= EvalSandbox.new(file: file, module_namespace: sandbox_module).call
    end

    attr_reader :parent_class_replacement, :file
  end
end