require "parser/current"
require "unparser"
require "dissociated_introspection/try"
require "dissociated_introspection/ruby_class"
require "dissociated_introspection/block"
require "dissociated_introspection/method_call"

RSpec.describe DissociatedIntrospection::RubyClass do

  it "#class_begin" do
    subject = described_class.new source: <<-RUBY
      module C
        class A < B
          def method
          end
        end
      end
    RUBY
    expect(subject.class_begin.to_s).to eq "(class\n  (const nil :A)\n  (const nil :B)\n  (def :method\n    (args) nil))"
  end

  describe "class_method_calls" do
    it "method call with primitives" do
      subject = described_class.new source: <<-RUBY
      class A
        attr_reader :name, "hello"
      end
      RUBY
      expect(subject.class_method_calls.first.to_h).to eq(name: :attr_reader, arguments: [:name, "hello"])
    end

    it "methods call with lambda block" do
      subject = described_class.new source: <<-RUBY
      class A
        scope :find_all_people, ->(a, _) {
          value = a + 1
          return 3 if value == 2
        }
      end
      RUBY
      expect(subject.class_method_calls.first.name).to eq(:scope)
      expect(subject.class_method_calls.first.arguments.first).to eq(:find_all_people)
      expect(subject.class_method_calls.first.arguments.last.body.source).to eq("value = (a + 1)\nif (value == 2)\n  return 3\nend")
      expect(subject.class_method_calls.first.arguments.last.arguments.source).to eq("a, _")
    end
  end

  describe "#class_name" do

    it "returns the class name as a symbol" do
      subject = described_class.new source: <<-RUBY
      require "uri-open"

      class A < B
        def method1
        end
      end
      RUBY
      expect(subject.class_name).to eq "A"
      expect(subject.defs.count).to eq 1
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

  describe "#parent_class?" do

    it "has parent class" do
      subject = described_class.new source: <<-RUBY
      require "uri-open"
      class A < B
        def method
        end
      end
      RUBY
      expect(subject.parent_class?).to eq true

      subject = described_class.new source: <<-RUBY
      class A < B
        def method
        end
      end
      RUBY
      expect(subject.parent_class?).to eq true
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
      expect(subject.parent_class?).to eq true
    end

    it "has no parent class" do
      subject = described_class.new source: <<-RUBY
      require "uri-open"
      class A
        def method
        end
      end
      RUBY
      expect(subject.parent_class?).to eq false

      subject = described_class.new source: <<-RUBY
      class A
        def method
        end
      end
      RUBY
      expect(subject.parent_class?).to eq false
    end

    it "its not a class" do
      subject = described_class.new source: <<-RUBY
      def method

      end
      RUBY
      expect(subject.parent_class?).to eq false
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
      expect(subject.modify_parent_class("C").source).to eq "class A < C\n  def method(name:)\n  end\nend"

      subject = described_class.new source: <<-RUBY
      require "uri-open"
      class A < B
        def method(name:)
        end
      end
      RUBY
      expect(subject.modify_parent_class("C").source).to eq "class A < C\n  def method(name:)\n  end\nend"
    end

    it "will change parent class const with module" do
      subject = described_class.new source: <<-RUBY
      class A < B::D::C
        def method(name:)
        end
      end
      RUBY
      expect(subject.modify_parent_class("X::Y").source).to eq "class A < X::Y\n  def method(name:)\n  end\nend"
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
      expect(subject.modify_parent_class("Y::Z").source).to eq "class A < Y::Z\n  def method\n  end\nend"
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
      expect(subject.modify_parent_class("Y::Z").source).to eq "class C < Y::Z\n  def method\n  end\nend"
    end

    it "if non set it will add the parent" do
      subject = described_class.new source: <<-RUBY
      class A
        def method(*args)
        end
      end
      RUBY
      expect(subject.modify_parent_class("C").source).to eq "class A < C\n  def method(*args)\n  end\nend"
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
      expect(subject.change_class_name("C").source).to eq "class C\n  def method(options = {})\n  end\nend"
    end
  end

  describe "#class?" do

    it "is a class" do
      subject = described_class.new source: <<-RUBY
      class A
        def method(options={})
        end
      end
      RUBY
      expect(subject.class?).to eq true
    end

    it "is not a class" do
      subject = described_class.new source: <<-RUBY
        def method(options={})
        end
      RUBY
      expect(subject.class?).to eq false
    end
  end

  describe "defs" do
    let(:ruby_class) {
      <<-RUBY
      class A
        def method1(arg, named_arg:)
          1+1
        end

        # This is a comment
        def method2(arg=nil)
          puts "hello"
        end
      end
      RUBY
    }

    subject {
      described_class.new(
          DissociatedIntrospection::RubyCode.build_from_source(
              ruby_class,
              parse_with_comments: true
          )
      )
    }

    it "returns a list of methods as Def object" do
      expect(subject.defs.map(&:class).uniq).to eq [described_class::Def]
    end

    describe "Def object" do
      it "name" do
        expect(subject.defs.first.name).to eq :method1
        expect(subject.defs.last.name).to eq :method2
      end

      it "argument" do
        expect(subject.defs.first.arguments.to_s).to eq "arg, named_arg:"
        expect(subject.defs.last.arguments.to_s).to eq "arg = nil"
      end

      it "body" do
        expect(subject.defs.first.body.source).to eq "1 + 1"
        expect(subject.defs.last.body.source).to eq "puts(\"hello\")"
      end

      it "source" do
        expect(subject.defs.first.source).to eq "def method1(arg, named_arg:)\n  1 + 1\nend"
        expect(subject.defs.last.source).to eq "# This is a comment\ndef method2(arg = nil)\n  puts(\"hello\")\nend"
      end

      describe "inspect_methods" do
        it "name" do
          expect(subject.inspect_methods(:instance_methods).first.name).to eq :method1
          expect(subject.inspect_methods(:instance_methods).last.name).to eq :method2
        end
      end
    end
  end

  describe "class_defs" do
    let(:ruby_class) {
      <<-RUBY
      class A
        # my comment
        def self.method1(arg, named_arg:)
          1+1
        end

        class << self
          # This is a comment
          def method2(arg=nil)
            puts "hello"
          end

          def method3(**args)
            puts "goodbye"
          end
        end
      end
      RUBY
    }

    subject {
      described_class.new(
          DissociatedIntrospection::RubyCode.build_from_source(
              ruby_class,
              parse_with_comments: true
          )
      )
    }

    describe "Def object" do
      it "name" do
        expect(subject.class_defs.first.name).to eq :method1
        expect(subject.class_defs[1].name).to eq :method2
        expect(subject.class_defs[2].name).to eq :method3
      end

      it "argument" do
        expect(subject.class_defs.first.arguments.to_s).to eq "arg, named_arg:"
        expect(subject.class_defs[1].arguments.to_s).to eq "arg = nil"
        expect(subject.class_defs[2].arguments.to_s).to eq "**args"
      end

      it "body" do
        expect(subject.class_defs.first.body.source).to eq "1 + 1"
        expect(subject.class_defs[1].body.to_s).to eq "puts(\"hello\")"
        expect(subject.class_defs[2].body.to_s).to eq "puts(\"goodbye\")"
      end

      it "source" do
        expect(subject.class_defs.first.to_s).to eq "# my comment\ndef method1(arg, named_arg:)\n  1 + 1\nend"
        expect(subject.class_defs[1].source).to eq "# This is a comment\ndef method2(arg = nil)\n  puts(\"hello\")\nend"
        expect(subject.class_defs[2].source).to eq "def method3(**args)\n  puts(\"goodbye\")\nend"
      end

      context "single method" do
        let(:ruby_class) {
          <<-RUBY
          class A
            class << self
              def foo
                :buz
              end
            end
          end
          RUBY
        }

        it "class_defs" do
          expect(subject.class_defs.first.name).to eq :foo
          expect(subject.class_defs.first.arguments.to_s).to eq ""
          expect(subject.class_defs.first.body.to_s).to eq ":buz"
        end
      end

      describe "inspect_methods" do
        it "name" do
          expect(subject.inspect_methods(:class_methods).first.name).to eq :method1
          expect(subject.inspect_methods(:methods)[1].name).to eq :method2
          expect(subject.inspect_methods(:methods)[2].name).to eq :method3
        end
      end
    end
  end

  describe "#scrub_inner_classes" do
    let(:ruby_class) {
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
      expect(subject.scrub_inner_classes.source).to eq("class include(MyModule) < def keep_me\nend\n  def self.hello\n  end\nend")
    end
  end

  describe "#defined_nested_modules" do
    let(:ruby_class) {
      <<-RUBY
      require "bla"
      class A
        module MyError
          def hello
            :good_day
          end
        end
        include MyError
        
      end
      RUBY
    }

    subject { described_class.new(source: ruby_class) }

    it "RubyCode object of defined nested modules" do
      expect(subject.defined_nested_modules.map(&:source).map(&:chomp)).to eq(["module MyError\n  def hello\n    :good_day\n  end\nend"])
    end
  end

  describe "#defined_nested_classes" do
    let(:ruby_class) {
      <<-RUBY
      require "bla"
      class A
        class MyError
          def hello
            :good_day
          end
        end
      end
      RUBY
    }

    subject { described_class.new(source: ruby_class) }

    it "RubyCode object of defined nested classess" do
      expect(subject.defined_nested_classes.map(&:source)).to eq(["class MyError\n  def hello\n    :good_day\n  end\nend"])
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
