require_relative './../../spec_helper'

describe Arango::Client do
  context "#verbose" do
    it "try verbose" do
      @client.verbose = true
      result = @myDatabase.collection(name: "Test").create
      expect(result.class).to be Hash
    end

    it "print verbose" do
      @client.verbose = true
      expect(@client.verbose).to be true
    end
  end
end
