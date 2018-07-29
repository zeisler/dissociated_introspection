class RecordingParent < BasicObject
  class << self
    def method_missing(m, *args, &block)
      __missing_class_macros__.push({ m => [args, block].compact })
    end

    def __missing_class_macros__
      @__missing_class_macros__ ||= []
    end

    module ConstMissing
      def const_missing(const_sym)
        if const_defined?("::#{const_sym}")
          Kernel.const_get("::#{const_sym}")
        else
          const = self.const_set(const_sym, Module.new)
          const.extend ConstMissing
          const.module_eval(<<-RUBY, __FILE__, __LINE__+1)
                    def self.name
                      "#{name.gsub(/#<Module:.*>::/, '')}::#{const_sym}"
                    end

                    def self.inspect
                      name
                    end
          RUBY
          RecordingParent.__missing_constants__[const_sym] = const
          const
        end
      end
    end

    include ConstMissing

    def __missing_constants__
      # This file and it's class variables are reinitialized within a new module namespace on every run.
      @@__missing_constants__ ||= {}
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

  listen_to_defined_macros *DissociatedIntrospection.listen_to_defined_class_methods
end

