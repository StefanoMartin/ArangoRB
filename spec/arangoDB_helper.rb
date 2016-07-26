require 'spec_helper'

describe ArangoDB do
  before :all do
    ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
    ArangoS.database = "MyDatabase"
    @myDatabase = ArangoDB.new
  end

  context "#new" do
    it "create a new instance without global" do
      myDatabase = ArangoDB.new database: "MyDatabase"
      expect(myDatabase.database).to eq "MyDatabase"
    end

    it "create a new instance with global" do
      myDatabase = ArangoDB.new
      expect(myDatabase.database).to eq "MyDatabase"
    end
  end

  context "#create" do
    it "create a new Database" do
      myDatabase = @myDatabase.create
      expect(myDatabase.database).to eq "MyDatabase"
    end

    it "create a duplicate Database" do
      myDatabase = @myDatabase.create
      expect(myDatabase).to eq "duplicate name"
    end
  end

  context "#info" do
    it "obtain general info" do
      info = ArangoDB.info
      expect(info["name"]).to eq "_system"
    end

    it "list databases" do
      list = ArangoDB.databases
      expect(list.length).to be >= 1
    end

    it "list collections" do
      list = @myDatabase.collections
      expect(list.length).to be 0
    end

    it "list graphs" do
      list = @myDatabase.graphs
      expect(list.length).to be 0
    end
  end

  context "#destroy" do
    it "delete a Database" do
      myDatabase = @myDatabase.destroy
      expect(myDatabase).to be true
    end
  end
end
