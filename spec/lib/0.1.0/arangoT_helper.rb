require_relative './../../spec_helper'

describe ArangoT do
  # before :all do
  #   ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
  #   ArangoS.database = "MyDatabase"
  #   ArangoS.collection = "MyCollection"
  #   ArangoS.graph = "MyGraph"
  #   ArangoDB.new.create
  #   @myGraph = ArangoG.new.create
  #   @myCollection = ArangoC.new.create
  #   @myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
  #   @myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
  #   @myTraversal = ArangoT.new
  #   @myDoc = @myCollection.create_document document: [{"num" => 1, "_key" => "FirstKey"}, {"num" => 2}, {"num" => 3}, {"num" => 4}, {"num" => 5}, {"num" => 6}, {"num" => 7}]
  #   @myEdgeCollection.create_edge from: [@myDoc[0].id, @myDoc[1].id, @myDoc[2].id, @myDoc[3].id], to: [@myDoc[4].id, @myDoc[5].id, @myDoc[6].id]
  # end
  #
  # after :all do
  #   ArangoDB.new.destroy
  # end

  context "#new" do
    it "create a new Traversal instance" do
      myTraversal = ArangoT.new
      expect(myTraversal.database).to eq "MyDatabase"
    end

    it "instantiate start Vertex" do
      @myTraversal.vertex = @myDoc[0]
      expect(@myTraversal.vertex).to eq "MyCollection/FirstKey"
    end

    it "instantiate Graph" do
      @myTraversal.graph = @myGraph
      expect(@myTraversal.graph).to eq @myGraph.graph
    end

    it "instantiate EdgeCollection" do
      @myTraversal.collection = @myEdgeCollection
      expect(@myTraversal.collection).to eq @myEdgeCollection.collection
    end

    it "instantiate Direction" do
      @myTraversal.in
      expect(@myTraversal.direction).to eq "inbound"
    end

    it "instantiate Max" do
      @myTraversal.max = 3
      expect(@myTraversal.max).to eq 3
    end

    it "instantiate Min" do
      @myTraversal.min = 1
      expect(@myTraversal.min).to eq 1
    end
  end

  context "#execute" do
    it "execute Traversal" do
      @myTraversal.any
      @myTraversal.execute
      expect(@myTraversal.vertices.length).to be >= 30
    end
  end
end
