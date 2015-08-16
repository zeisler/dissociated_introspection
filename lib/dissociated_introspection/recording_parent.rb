module DissociatedIntrospection
  class RecordingParent < BasicObject
    class << self

      def method_missing(m, *args, &block)
        __missing_class_macros__.push({ m => [args, block].compact })
      end

      def __missing_class_macros__
        @__missing_class_macros__ ||= []
      end

      def listen_to_defined_macros(*methods)
        methods.each do |m|
          module_eval(<<-RUBY, __FILE__)
            def self.#{m}(*args, &block)
              __missing_class_macros__.push({ __method__ => [args, block].compact })
            end
          RUBY
        end
      end
    end

    listen_to_defined_macros :attr_reader, :attr_writer, :attr_accessor, :prepend, :include, :extend
  end
end