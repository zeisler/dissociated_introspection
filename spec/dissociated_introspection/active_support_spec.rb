require "spec_helper"
require "dissociated_introspection/active_support"

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