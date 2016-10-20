require 'ostruct'

module DissociatedIntrospection
  class Inspection

    # @param file [File]
    # @optional parent_class_replacement [Symbol]
    def initialize(file:, parent_class_replacement: :RecordingParent)
      @file                     = file
      @parent_class_replacement = parent_class_replacement
    end

    # @return [Class]
    def get_class
      @get_class ||= get_sandbox_class
    end

    # @return [Array]
    def class_macros
      get_class.__missing_class_macros__
    end

    # @return [Array<Module>]
    def extended_modules
      find_class_macro_by_type(:extend) { |a| add_method_referenced_name a.first }
    end

    # @return [Array<Module>]
    def included_modules
      find_class_macro_by_type(:include) { |a| add_method_referenced_name a.first }
    end

    # @return [Array<Module>]
    def prepend_modules
      find_class_macro_by_type(:prepend) { |a| add_method_referenced_name a.first }
    end

    # @return [Hash{String => Module}]
    def missing_constants
      get_class.__missing_constants__
    end

    # @optional type [Module, Class, Any]
    # @return [Hash{Symbol => Any}>]
    def locally_defined_constants(type=nil)
      symbol_consts = get_class.constants - get_class.__missing_constants__.keys - [:BasicObject]
      consts = symbol_consts.each_with_object({}){|c, hash| hash[c] = get_class.const_get(c) }
      type ? consts.select { |s, c| c.is_a?(type) } : consts
    end

    # @return [DissociatedIntrospection::RubyClass]
    def parsed_source
      @parsed_source ||= RubyClass.new(source: file.read, parse_with_comments: true)
    end

    # @return [Module]
    def sandbox_module
      @sandbox_module ||= Module.new
    end

    private

    def add_method_referenced_name(_module)
      _class_name_ = parsed_source.class_name

      _module.define_singleton_method(:referenced_name) do
        n = name.split("::")
        n = n.drop(1) if n.first =~ /#<Module:.*>/
        n = n.drop(1) if n.first == _class_name_
        return n.join("::")
      end
      _module
    end

    def find_class_macro_by_type(type)
      get_class.__missing_class_macros__.select { |h| h.keys.first == type }.map { |h| yield(h.values.first.first) }
    end

    def get_sandbox_class
      modified_class_source = parsed_source.modify_parent_class(parent_class_replacement)
      path                  = if file.is_a? Pathname
                                file.to_s
                              else
                                file.path
                              end
      load_sandbox(OpenStruct.new(read: modified_class_source.to_ruby_str, path: path))
    end

    def load_sandbox(file)
      @klass ||= EvalSandbox.new(file: file, module_namespace: sandbox_module).call
    end

    attr_reader :parent_class_replacement, :file
  end
end
