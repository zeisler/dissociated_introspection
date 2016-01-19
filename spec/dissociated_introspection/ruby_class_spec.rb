require "parser/current"
require "unparser"
require "dissociated_introspection/try"
require "dissociated_introspection/ruby_class"

RSpec.describe DissociatedIntrospection::RubyClass do

  describe "#class_name" do

    it "returns the class name as a symbol" do
      subject = described_class.new source: <<-RUBY
      require "uri-open"

      class A < B
        def method
        end
      end
      RUBY
      expect(subject.class_name).to eq "A"
    end
  end

  describe "#parent_class_name" do

    it "returns the parent class as a symbol" do
      subject = described_class.new source: <<-RUBY
      require "uri-open"
      class A < B
        def method
        end
      end
      RUBY
      expect(subject.parent_class_name).to eq "B"
    end

    it "returns the parent class as a symbol with modules" do
      subject = described_class.new source: <<-RUBY
      class A < B::C
        def method
        end
      end
      RUBY
      expect(subject.parent_class_name).to eq "B::C"
    end
  end

  describe "#has_parent_class?" do

    it "has parent class" do
      subject = described_class.new source: <<-RUBY
      require "uri-open"
      class A < B
        def method
        end
      end
      RUBY
      expect(subject.has_parent_class?).to eq true

      subject = described_class.new source: <<-RUBY
      class A < B
        def method
        end
      end
      RUBY
      expect(subject.has_parent_class?).to eq true
    end

    it "has parent class within module" do
      subject = described_class.new source: <<-RUBY
      module C
        class A < B
          def method
          end
        end
      end
      RUBY
      expect(subject.has_parent_class?).to eq true
    end

    it "has no parent class" do
      subject = described_class.new source: <<-RUBY
      require "uri-open"
      class A
        def method
        end
      end
      RUBY
      expect(subject.has_parent_class?).to eq false

      subject = described_class.new source: <<-RUBY
      class A
        def method
        end
      end
      RUBY
      expect(subject.has_parent_class?).to eq false
    end

    it "its not a class" do
      subject = described_class.new source: <<-RUBY
      def method

      end
      RUBY
      expect(subject.has_parent_class?).to eq false
    end
  end

  describe "#modify_parent_class" do

    it "will change parent class const" do
      subject = described_class.new source: <<-RUBY
      class A < B
        def method(name:)
        end
      end
      RUBY
      expect(subject.modify_parent_class("C").to_ruby_str).to eq "class A < C\n  def method(name:)\n  end\nend"

      subject = described_class.new source: <<-RUBY
      require "uri-open"
      class A < B
        def method(name:)
        end
      end
      RUBY
      expect(subject.modify_parent_class("C").to_ruby_str).to eq "class A < C\n  def method(name:)\n  end\nend"
    end

    it "will change parent class const with module" do
      subject = described_class.new source: <<-RUBY
      class A < B::D::C
        def method(name:)
        end
      end
      RUBY
      expect(subject.modify_parent_class("X::Y").to_ruby_str).to eq "class A < X::Y\n  def method(name:)\n  end\nend"
    end

    it "will change parent class const within a module but will not return the module" do
      subject = described_class.new source: <<-RUBY
      module C
        class A < B
          def method
          end
        end
      end
      RUBY
      expect(subject.modify_parent_class("Y::Z").to_ruby_str).to eq "class A < Y::Z\n  def method\n  end\nend"
    end

    it "will change parent class const within a doubly nested class" do
      subject = described_class.new source: <<-RUBY
      module A
        module B
          class C < D
            def method
            end
          end
        end
      end
      RUBY
      expect(subject.modify_parent_class("Y::Z").to_ruby_str).to eq "class C < Y::Z\n  def method\n  end\nend"
    end

    it "if non set it will add the parent" do
      subject = described_class.new source: <<-RUBY
      class A
        def method(*args)
        end
      end
      RUBY
      expect(subject.modify_parent_class("C").to_ruby_str).to eq "class A < C\n  def method(*args)\n  end\nend"
    end
  end

  describe "#change_class_name" do

    it "will change the class constant" do
      subject = described_class.new source: <<-RUBY
      class A
        def method(options={})
        end
      end
      RUBY
      expect(subject.change_class_name("C").to_ruby_str).to eq "class C\n  def method(options = {})\n  end\nend"
    end
  end

  describe "#is_class?" do

    it "is a class" do
      subject = described_class.new source: <<-RUBY
      class A
        def method(options={})
        end
      end
      RUBY
      expect(subject.is_class?).to eq true
    end

    it "is not a class" do
      subject = described_class.new source: <<-RUBY
        def method(options={})
        end
      RUBY
      expect(subject.is_class?).to eq false
    end
  end
  
  describe "defs" do
    let(:ruby_class){
      <<-RUBY
      class A
        def method1(arg, named_arg:)
          1+1
        end
        def method2(arg=nil)
          puts "hello"
        end
      end
      RUBY
    }

    subject { described_class.new(source: ruby_class) }

    it "returns a list of methods as Def object" do
      expect(subject.defs.map(&:class).uniq).to eq [described_class::Def]
    end

    describe "Def object" do

      it "name" do
        expect(subject.defs.first.name).to eq :method1
        expect(subject.defs.last.name).to eq :method2
      end

      it "argument" do
        expect(subject.defs.first.arguments).to eq "arg, named_arg:"
        expect(subject.defs.last.arguments).to eq "arg = nil"
      end

      it "body" do
        expect(subject.defs.first.body).to eq "1 + 1"
        expect(subject.defs.last.body).to eq "puts(\"hello\")"
      end

      it "to_ruby_str" do
        expect(subject.defs.first.to_ruby_str).to eq "def method1(arg, named_arg:)\n  1 + 1\nend"
        expect(subject.defs.last.to_ruby_str).to eq "def method2(arg = nil)\n  puts(\"hello\")\nend"
      end
    end
  end

  describe "#scrub_inner_classes" do
    let(:ruby_class){
      <<-RUBY
      require "bla"
      class A
        include MyModule
        class MyError < StandardError;end
        def keep_me
        end
        def self.hello
        end
      end
      RUBY
    }

    subject { described_class.new(source: ruby_class) }

    it "will return a ruby string without the inner class" do
      expect(subject.scrub_inner_classes.to_ruby_str).to eq("class include(MyModule) < def keep_me\nend\n  def self.hello\n  end\nend")
    end
  end

  describe "module_nesting" do
    subject { described_class.new(source: ruby_class) }

    context "single nesting" do
      let(:ruby_class) {
        <<-RUBY
      module Api
        class MyClass < OtherClass
          ParentModule::NestedModule
        end
       end
        RUBY
      }


      it "returns the module nesting" do
        expect(subject.module_nesting).to eq [:Api]
      end
    end

    context "double nesting" do
      let(:ruby_class) {
        <<-RUBY
      module Api
        module Namespace
        class MyClass
          module IgnoreMe
          end
        end
        end
       end
        RUBY
      }

      it "returns the module nesting" do
        expect(subject.module_nesting).to eq [:Api, :Namespace]
      end
    end

    context "no nesting" do
      let(:ruby_class) {
        <<-RUBY
        class MyClass
        end
        RUBY
      }

      it "returns the module nesting" do
        expect(subject.module_nesting).to eq []
      end
    end
  end
end
