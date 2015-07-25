require 'spec_helper'
require 'unparser'
require 'dissociated_introspection/tryable'
require 'dissociated_introspection/eval_sandbox'
require 'dissociated_introspection/inspection'
require 'dissociated_introspection/ruby_class'
require 'dissociated_introspection/recording_parent'

RSpec.describe DissociatedIntrospection::Inspection do
  describe "#call" do
    let(:file) { instance_double(File, read: ruby_class, path: '') }

    context 'MyClass' do
      let(:ruby_class) {
        <<-RUBY
      class MyClass < OtherClass
        attr_writer :foo, :bar
        attr_reader :foo
        attr_accessor :baz
      end
        RUBY
      }

      it "#class_name" do
        expect(described_class.new(file: file).class_name).to eq("MyClass")
      end

      it "get_class" do
        expect(described_class.new(file: file).get_class.superclass).to eq(DissociatedIntrospection::RecordingParent)
      end

      it 'intercepts class macros' do
        expect(described_class.new(file: file).class_macros).to eq([{ :attr_writer => [[:foo, :bar], nil] },
                                                                    { :attr_reader => [[:foo], nil] },
                                                                    { :attr_accessor => [[:baz], nil] }])
      end
    end

    context 'TheClass' do
      let(:ruby_class) {
        <<-RUBY
      class TheClass < OtherClass
        class_macro :foo, :bar
        another_method :bax
      end
        RUBY
      }

      it "#class_name" do
        expect(described_class.new(file: file).class_name).to eq("TheClass")
      end

      it 'intercepts class macros' do
        expect(described_class.new(file: file).class_macros).to eq([{ class_macro: [[:foo, :bar], nil] },
                                                                    { another_method: [[:bax], nil] }])
      end
    end
  end
end
