require 'parser/current'
require 'unparser'
require 'forwardable'
require 'dissociated_introspection/version'
require 'dissociated_introspection/try'
require 'dissociated_introspection/eval_sandbox'
require 'dissociated_introspection/wrap_in_modules'
require 'dissociated_introspection/ruby_code'
require 'dissociated_introspection/ruby_class'
require 'dissociated_introspection/ruby_class/def'
require 'dissociated_introspection/method_in_liner'
require 'dissociated_introspection/inspection'
require 'dissociated_introspection/method_call'

module DissociatedIntrospection
  LISTEN_TO_CLASS_METHODS = [
    :attr_reader,
    :attr_writer,
    :attr_accessor,
    :prepend,
    :include,
    :extend,
    :alias_attribute,
    :alias_method,
    :alias_method_chain
  ]

  class << self
    def listen_to_defined_class_methods=(*methods)
      listen_to_defined_class_methods.concat(methods)
    end

    def listen_to_defined_class_methods
      @listen_to_defined_class_methods ||= LISTEN_TO_CLASS_METHODS
    end
  end
end
