require 'spec_helper'
require 'dissociated_introspection'

RSpec.describe DissociatedIntrospection::Inspection do
  let(:file) { instance_double(File, read: ruby_class, path: '') }

  describe "#parsed_source" do
    let(:ruby_class) {
      <<-RUBY
      class MyClass < OtherClass
      end
      RUBY
    }

    it "returns a RubyClass instance" do
      expect(described_class.new(file: file).parsed_source.class).to eq(DissociatedIntrospection::RubyClass)
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
      expect(described_class.new(file: file).get_class.name).to match(/MyClass/)
    end

    it "superclass is the altered parent class" do
      expect(described_class.new(file: file).get_class.superclass.name).to match(/RecordingParent/)
    end
  end

  describe "XXed_modules" do
    let(:ruby_class) {
      <<-RUBY
        class MyClass < OtherClass
          include MyModule
          include MyModule1
          extend MyModule2
          module MyModule3
          end
          extend MyModule3
          prepend MyModule4::NestedModule
        end
      RUBY
    }

    it 'extended_modules' do
      expect(described_class.new(file: file).extended_modules.map(&:name_wo_parent)).to eq(["MyModule2", "MyModule3"])
    end

    it 'included_modules' do
      expect(described_class.new(file: file).included_modules.map(&:inspect)).to eq(["MyClass::MyModule", "MyClass::MyModule1"])
      expect(described_class.new(file: file).included_modules.map(&:name)).to eq(["MyClass::MyModule", "MyClass::MyModule1"])
      expect(described_class.new(file: file).included_modules.map(&:name_wo_parent)).to eq(["MyModule", "MyModule1"])
    end

    it 'prepend_modules' do
      expect(described_class.new(file: file).prepend_modules.map(&:inspect)).to eq(["MyClass::MyModule4::NestedModule"])
      expect(described_class.new(file: file).prepend_modules.map(&:name)).to eq(["MyClass::MyModule4::NestedModule"])
      expect(described_class.new(file: file).prepend_modules.map(&:name_wo_parent)).to eq(["MyModule4::NestedModule"])
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
      expect(described_class.new(file: file).class_macros).to eq([{ :attr_writer => [[:foo, :bar]] },
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
        expect(described_class.new(file: file).class_macros[0][:include][0][0].name).to match(/MyClass::MyModule/)
      end

      it 'extend' do
        expect(described_class.new(file: file).class_macros[1][:extend][0][0].name).to match(/MyClass::MyModule/)
      end

      it 'prepend' do
        expect(described_class.new(file: file).class_macros[2][:prepend][0][0].name).to match(/MyClass::MyModule/)
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
        expect(described_class.new(file: file).class_macros[0][:i_take_a_block][0]).to eq([:hello])
      end

      it 'block' do
        expect(described_class.new(file: file).class_macros[0][:i_take_a_block][1].class).to eq(Proc)
      end

      it 'proc will execute' do
        expect(described_class.new(file: file).class_macros[0][:i_take_a_block][1].call).to eq('hi')
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
        result = described_class.new(file: file).missing_constants
        expect(result[:SingleModule].class)
            .to eq(Module)
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
        result = described_class.new(file: file).missing_constants.values
        expect(result.map(&:name)).to eq(["MyClass::ParentModule", "MyClass::ParentModule::NestedModule"])
      end

      it "is generated and recorded in a Hash" do
        result = described_class.new(file: file).missing_constants
        expect(result.size).to eq 2
        expect(result[:NestedModule].class).to eq(Module)
        expect(result[:ParentModule].class).to eq(Module)
      end

      it "generates the modules within their nesting" do
        klass = described_class.new(file: file).get_class
        expect(klass::ParentModule::NestedModule.name).to eq("MyClass::ParentModule::NestedModule")
        expect(klass::ParentModule.constants).to eq([:NestedModule])
      end
    end
  end
end
