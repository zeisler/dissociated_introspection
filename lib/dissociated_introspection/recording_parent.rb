module DissociatedIntrospection
  class RecordingParent
    class << self

      def method_missing(m, *args, &block)
        __missing_class_macros__.push({ m => [args, block] })
      end

      def __missing_class_macros__
        @__missing_class_macros__ ||= []
      end

      def attr_reader(*args)
        __missing_class_macros__.push({ __method__ => [args, nil] })
      end

      def attr_writer(*args)
        __missing_class_macros__.push({ __method__ => [args, nil] })
      end

      def attr_accessor(*args)
        __missing_class_macros__.push({ __method__ => [args, nil] })
      end

    end
  end
end