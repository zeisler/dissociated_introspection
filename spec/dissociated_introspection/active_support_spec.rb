require "spec_helper"
require "dissociated_introspection/active_support"
require "Tempfile"

describe ActiveSupport::Try do
  using ActiveSupport::Try

  describe "Object.try" do

    it "does not respond to method" do
      expect(Hash.new.try(:hello)).to eq nil
    end

    it "does respond to method" do
      expect({key1: 'value1'}.try(:keys)).to eq [:key1]
    end

    it "takes a block" do
      expect({ key1: 'value1' }.try{ keys }).to eq [:key1]
    end

    it "Arguments and blocks are forwarded to the method if invoked" do
      expect([1, 2, 3].try(:slice, 1) { to_s }).to eq 2
    end

    it "If try is called without arguments it yields the receiver to a given" do
      inside_block = nil
      "person".try do |p|
        inside_block = p
      end
      expect(inside_block).to eq "person"
    end
  end

  describe "Delegator.try" do

    it "does not respond to method" do
      expect(Tempfile.new('').try(:hello)).to eq nil
    end

    it "does respond to method" do
      expect(Tempfile.new('').try(:path)).to_not be_nil
    end
  end

  describe "NilClass.try" do

    it "always returns nil" do
      expect(nil.try(:hello)).to eq nil
      expect(nil.try(:to_i)).to eq nil
    end
  end
end