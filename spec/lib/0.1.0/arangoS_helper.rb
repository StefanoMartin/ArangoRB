require_relative './../../spec_helper'

describe ArangoServer do
  context "#database" do
    it "setup a global database" do
      ArangoServer.database = "MyDatabase"
      expect(ArangoServer.database).to eq "MyDatabase"
    end
  end

  context "#graph" do
    it "setup a global graph" do
      ArangoServer.graph = "MyGraph"
      expect(ArangoServer.graph).to eq "MyGraph"
    end
  end

  context "#collection" do
    it "setup a global collection" do
      ArangoServer.collection = "MyCollection"
      expect(ArangoServer.collection).to eq "MyCollection"
    end
  end

  context "#verbose" do
    it "try verbose" do
      ArangoServer.verbose = true
      result = ArangoCollection.new(collection: "Test").create
      expect(result.class).to be Hash
    end

    it "print verbose" do
      ArangoServer.verbose = true
      expect(ArangoServer.verbose).to be true
    end
  end
end
