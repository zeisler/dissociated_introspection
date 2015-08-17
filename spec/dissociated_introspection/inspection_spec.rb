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
      end
      RUBY
    }

    it "returns the sandboxed class" do
      expect(described_class.new(file: file).get_class.name).to match(/MyClass/)
    end

    it "superclass is the altered parent class" do
      expect(described_class.new(file: file).get_class.superclass).to eq(DissociatedIntrospection::RecordingParent)
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

    it 'records attr_* macros' do
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
        MyModule
      end
        RUBY
      }

      it 'creates a blank module' do
        expect(described_class.new(file: file).missing_constants[:MyModule].class)
          .to eq(Module)
      end
    end
  end
end
