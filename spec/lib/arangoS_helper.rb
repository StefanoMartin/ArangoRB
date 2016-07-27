require_relative './../spec_helper'

describe ArangoS do
  before :all do
    ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
  end

  context "#database" do
    it "setup a global database" do
      ArangoS.database = "MyDatabase"
      expect(ArangoS.database).to eq "MyDatabase"
    end
  end

  context "#graph" do
    it "setup a global graph" do
      ArangoS.graph = "MyGraph"
      expect(ArangoS.graph).to eq "MyGraph"
    end
  end

  context "#collection" do
    it "setup a global collection" do
      ArangoS.collection = "MyCollection"
      expect(ArangoS.collection).to eq "MyCollection"
    end
  end
end
