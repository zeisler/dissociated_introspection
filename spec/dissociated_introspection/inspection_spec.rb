require 'spec_helper'
require 'dissociated_introspection'

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

      it "#ruby_class_source#class_name" do
        expect(described_class.new(file: file).parsed_source.class_name).to eq("MyClass")
      end

      it "get_class" do
        expect(described_class.new(file: file).get_class.superclass).to eq(DissociatedIntrospection::RecordingParent)
      end

      it 'intercepts class macros' do
        expect(described_class.new(file: file).class_macros).to eq([{ :attr_writer => [[:foo, :bar]] },
                                                                    { :attr_reader => [[:foo]] },
                                                                    { :attr_accessor => [[:baz]] }])
      end
    end

    describe "method that takes a block" do
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
        expect(described_class.new(file: file).parsed_source.class_name).to eq("TheClass")
      end

      it 'intercepts class macros' do
        expect(described_class.new(file: file).class_macros).to eq([{ class_macro: [[:foo, :bar]] },
                                                                    { another_method: [[:bax]] }])
      end
    end
  end
end
