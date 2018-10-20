require_relative './../../spec_helper'

describe Arango::Traversal do
  context "#new" do
    it "creates new connections" do
      myDoc = @myCollection.createDocuments document: [
        {"B": 1}, {"B": 2}, {"B": 3}, {"B": 4}, {"B": 5},
        {"B": 6}, {"B": 7}, {"B": 8}, {"B": 9}, {"B": 10}]
      @myEdgeCollection.createEdges document: [{"ED": 1}, {"ED": 2}],
      from: [myDoc[0], myDoc[1], myDoc[2]], to: [myDoc[3], myDoc[4], myDoc[5]]
      @myEdgeCollection.createEdges document: [{"ED": 3}, {"ED": 4}],
      from: [myDoc[3], myDoc[4], myDoc[5]], to: [myDoc[6], myDoc[7]]
      val = @myEdgeCollection.createEdges document: [{"ED": 0}], from:  @myDoc[0], to: myDoc[0]
      expect(val[0].collection.type).to eq :edge
    end

    it "create a new Traversal instance" do
      myTraversal = @myDoc[0].traversal
      expect(myTraversal.database.name).to eq "MyDatabase"
    end

    it "instantiate start Vertex" do
      @myTraversal.vertex = @myDoc[0]
      expect(@myTraversal.vertex.id).to eq "MyCollection/FirstKey"
    end

    it "instantiate Graph" do
      @myTraversal.graph = @myGraph
      expect(@myTraversal.graph.name).to eq @myGraph.name
    end

    it "instantiate EdgeCollection" do
      @myTraversal.collection = @myEdgeCollection
      expect(@myTraversal.collection.name).to eq @myEdgeCollection.name
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
      @server.verbose = true
      @myTraversal.any
      @myTraversal.execute
      expect(@myTraversal.vertices.length).to be >= 30
    end
  end
end
