require 'spec_helper'
require 'dissociated_introspection'

RSpec.describe DissociatedIntrospection::Inspection do
  let(:file) { instance_double(File, read: ruby_class, path: '') }

  subject { described_class.new(file: file) }

  describe "#parsed_source" do
    let(:ruby_class) {
      <<-RUBY
      class MyClass < OtherClass
      end
      RUBY
    }

    it "returns a RubyClass instance" do
      expect(subject.parsed_source.class).to eq(DissociatedIntrospection::RubyClass)
    end
  end

  describe "#get_class" do
    let(:ruby_class) {
      <<-RUBY
      class MyClass < OtherClass
        def method1
        end

        include X
        extend Y
      end
      RUBY
    }

    it "returns the sandboxed class" do
      expect(subject.get_class.name).to match(/MyClass/)
    end

    it "superclass is the altered parent class" do
      expect(subject.get_class.superclass.name).to match(/RecordingParent/)
    end
  end

  describe "XXed_modules" do

    before do
      module ExternallyDefined
        module ModuleNested
        end
      end
    end

    let(:ruby_class) {
      <<-RUBY
        class MyClass < OtherClass
          include MyModule
          include MyModule1
          include ExternallyDefined::ModuleNested
          extend MyModule2
          module MyModule3
          end
          extend MyModule3
          prepend MyModule4::NestedModule
          prepend ExternallyDefined
        end
      RUBY
    }

    describe "#extended_modules" do
      it "#inspect" do
        expect(subject.extended_modules.map(&:inspect))
          .to eq(%W(MyClass::MyModule2 #{subject.sandbox_module}::MyClass::MyModule3))
      end

      it "#name" do
        expect(subject.extended_modules.map(&:name))
          .to eq(%W(MyClass::MyModule2 #{subject.sandbox_module}::MyClass::MyModule3))
      end

      it "#referenced_name" do
        expect(subject.extended_modules.map(&:referenced_name))
          .to eq(%w(MyModule2 MyModule3))
      end
    end

    describe "#included_modules" do
      it "#inspect" do
        expect(subject.included_modules.map(&:inspect))
          .to eq(%w(MyClass::MyModule MyClass::MyModule1 ExternallyDefined::ModuleNested))
      end

      it "#name" do
        expect(subject.included_modules.map(&:name))
          .to eq(%w(MyClass::MyModule MyClass::MyModule1 ExternallyDefined::ModuleNested))
      end

      it "#referenced_name" do
        expect(subject.included_modules.map(&:referenced_name))
          .to eq(%w(MyModule MyModule1 ExternallyDefined::ModuleNested))
      end
    end

    describe "#prepend_modules" do
      it "#inspect" do
        expect(subject.prepend_modules.map(&:inspect))
          .to eq(%w(MyClass::MyModule4::NestedModule ExternallyDefined))
      end

      it "#name" do
        expect(subject.prepend_modules.map(&:name))
          .to eq(%w(MyClass::MyModule4::NestedModule ExternallyDefined))
      end

      it "#referenced_name" do
        expect(subject.prepend_modules.map(&:referenced_name))
          .to eq(%w(MyModule4::NestedModule ExternallyDefined))
      end
    end
  end

  describe "#locally_defined_modules" do

    before do
      module ExternallyDefined
        module ModuleNested
        end
      end
    end

    let(:ruby_class) {
      <<-RUBY
      class MyClass < OtherClass
        MY_CONST = 1
        module MyModule1
        end

        module MyModule2
        end
        include ExternallyDefined::ModuleNested
        include MyModule1
        include MyModule2
        include MyModule3
        extend MyModule4
        prepend MyModule5
      end
      RUBY
    }

    it "returns an array of constant names" do
      expect(subject.locally_defined_constants)
        .to eq({ MY_CONST:  1,
                 MyModule1: subject.sandbox_module::MyClass::MyModule1,
                 MyModule2: subject.sandbox_module::MyClass::MyModule2 })
    end

    it "returns an array of constants by type" do
      expect(subject.locally_defined_constants(Module))
        .to eq({ MyModule1: subject.sandbox_module::MyClass::MyModule1,
                 MyModule2: subject.sandbox_module::MyClass::MyModule2 })
    end
  end

  describe "#class_macros" do
    let(:ruby_class) {
      <<-RUBY
      class MyClass < OtherClass
        attr_writer :foo, :bar
        attr_reader :foo
        attr_accessor :baz
      end
      RUBY
    }

    it "records attr_* macros" do
      expect(subject.class_macros).to eq([{ :attr_writer => [[:foo, :bar]] },
                                          { :attr_reader => [[:foo]] },
                                          { :attr_accessor => [[:baz]] }])
    end

    context "listens to methods inclusion macros" do
      let(:ruby_class) {
        <<-RUBY
        class MyClass < OtherClass
          module MyModule
          end
          include MyModule
          extend MyModule
          prepend MyModule
        end
        RUBY
      }

      it 'include' do
        expect(subject.class_macros[0][:include][0][0].name).to match(/MyClass::MyModule/)
      end

      it 'extend' do
        expect(subject.class_macros[1][:extend][0][0].name).to match(/MyClass::MyModule/)
      end

      it 'prepend' do
        expect(subject.class_macros[2][:prepend][0][0].name).to match(/MyClass::MyModule/)
      end
    end

    context "method that takes a block" do
      let(:ruby_class) {
        <<-RUBY
        class MyClass < OtherClass
          i_take_a_block(:hello) do
            'hi'
          end
        end
        RUBY
      }

      it 'first arg' do
        expect(subject.class_macros[0][:i_take_a_block][0]).to eq([:hello])
      end

      it 'block' do
        expect(subject.class_macros[0][:i_take_a_block][1].class).to eq(Proc)
      end

      it 'proc will execute' do
        expect(subject.class_macros[0][:i_take_a_block][1].call).to eq('hi')
      end
    end
  end

  describe "#missing_constants" do
    context "When referenced constant is not defined" do
      let(:ruby_class) {
        <<-RUBY
        class MyClass < OtherClass
          SingleModule
        end
        RUBY
      }

      it "creates a blank module" do
        result = subject.missing_constants
        expect(result[:SingleModule].class)
          .to eq(Module)
      end
    end

    context "Global Constants will not raise an error when uses as parent class" do
      let(:ruby_class) {
        <<-RUBY
        class MyClass < OtherClass
          class IncompleteData < StandardError; end
          class OtherError < SimpleDelegator; end
        end
        RUBY
      }

      it do
        expect(subject.missing_constants.values.map(&:name)).to eq([])
      end
    end

    context "When referenced nested constants are not defined" do
      let(:ruby_class) {
        <<-RUBY
        class MyClass < OtherClass
          ParentModule::NestedModule
        end
        RUBY
      }

      it "create a name with the proper namespace" do
        expect(subject.missing_constants.values.map(&:name))
          .to eq(["MyClass::ParentModule", "MyClass::ParentModule::NestedModule"])
      end

      it "is generated and recorded in a Hash" do
        expect(subject.missing_constants.size).to eq 2
        expect(subject.missing_constants[:NestedModule].class).to eq(Module)
        expect(subject.missing_constants[:ParentModule].class).to eq(Module)
      end

      it "generates the modules within their nesting" do
        expect(subject.get_class::ParentModule::NestedModule.name).to eq("MyClass::ParentModule::NestedModule")
        expect(subject.get_class::ParentModule.constants).to eq([:NestedModule])
      end
    end
  end
end
