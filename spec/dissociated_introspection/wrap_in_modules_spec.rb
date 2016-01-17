RSpec.describe DissociatedIntrospection::WrapInModules do

  let(:ruby_code_source) {
    <<-RUBY
      # comments
      class A
      end
    RUBY
  }
  let(:ruby_code) { DissociatedIntrospection::RubyCode.build_from_source(ruby_code_source) }
  subject { described_class.new(ruby_code: ruby_code) }

  it "no module string" do
    expect(subject.call(modules: "").source_from_ast).to eq("class A\nend")
  end

  it "no module nil" do
    expect(subject.call(modules: nil).source_from_ast).to eq("class A\nend")
  end

  it "single module" do
    expect(subject.call(modules: "B").source_from_ast).to eq("module B\n  class A\n  end\nend")
  end

  context "single module with comments" do
    let(:ruby_code) { DissociatedIntrospection::RubyCode.build_from_source(ruby_code_source, parse_with_comments: true) }
    it { expect(subject.call(modules: "B").source_from_ast).to eq("module B\n  # comments\n  class A\n  end\nend") }
  end

  it "two modules deep" do
    expect(subject.call(modules: "X::Y").source_from_ast).to eq("module X\n  module Y\n    class A\n    end\n  end\nend")
  end

  it "three modules deep" do
    expect(subject.call(modules: "X::Y::Z").source_from_ast).to eq("module X\n  module Y\n    module Z\n      class A\n      end\n    end\n  end\nend")
  end
end
