RSpec.describe DissociatedIntrospection::MethodInLiner do
  subject {
    described_class.new(
        ruby_code,
        defs: defs
    )
  }
  let(:ruby_code) { DissociatedIntrospection::RubyCode.build_from_source(ruby_code_str) }
  let(:defs) { DissociatedIntrospection::RubyClass.new(ruby_code).defs }
  let(:ruby_code_str) {
    <<~RUBY
        class A
          def run
            work
          end

          def work
            "done"
          end

          def no_method_calls
            puts "I'm not friends with the other methods"
          end

          def more_calls
            work + work
          end

          def not_on_self
            other.work
          end

          def explicit_self
            self.work
          end
  
          def work2(count)
            "done with " + count.to_s
          end

          def no_args_yet
            work2(1)
          end
        end
    RUBY
  }

  it "replaces local method calls with body from called method" do
    expect(subject.defs.first.name).to eq :run
    in_line_local_method_calls = subject.in_line
    ruby_in_lined_class = DissociatedIntrospection::RubyClass.new(in_line_local_method_calls)
    expect(ruby_in_lined_class.defs[0].body.source).to eq "\"done\""
    expect(ruby_in_lined_class.defs[1].body.source).to eq "\"done\""
    expect(ruby_in_lined_class.defs[2].body.source).to eq "puts(\"I'm not friends with the other methods\")"
    expect(ruby_in_lined_class.defs[3].body.source).to eq "\"done\" + \"done\""
    expect(ruby_in_lined_class.defs[4].body.source).to eq "other.work"
    expect(ruby_in_lined_class.defs[5].body.source).to eq "\"done\""
    expect(ruby_in_lined_class.defs[7].body.source).to eq "work2(1)"
  end
end
