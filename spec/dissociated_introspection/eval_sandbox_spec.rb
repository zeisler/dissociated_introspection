require 'spec_helper'
require 'dissociated_introspection/eval_sandbox'

RSpec.describe DissociatedIntrospection::EvalSandbox do
  let(:klass_example) {
    <<-RUBY
    class User
      def first_name
      end
    end
    RUBY
  }

  let(:file) { instance_double(File, read: klass_example, path: __FILE__) }

  describe 'new' do

    it 'returns a class that responds to first_name' do
      expect(described_class.new(file: file).call.new.respond_to?(:first_name)).to eq(true)
    end

    it 'will not respond other_method because it is outside the sandbox' do
      class User
        def other_method
        end
      end

      expect(described_class.new(file: file).call.new.respond_to?(:other_method)).to eq(false)
    end

    it "eval'd inside of module namespace" do
      expect(described_class.new(file: file).call.name).to match(/#<Module:.*>::User/)
    end

    context "takes a file_path for error logging in case of read error" do
      let(:klass_example) {
        <<-RUBY
      t () - = !
        RUBY
      }

      let(:file) { instance_double(File, read: klass_example, path: __FILE__) }

      it do
        expect { described_class.new(file: file).call }.to raise_error(SyntaxError, /#{__FILE__}/)
      end
    end
  end
end