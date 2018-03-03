require_relative './../../spec_helper'

describe Arango::Traversal do
  context "#new" do
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
      expect(@myTraversal.graph.name).to eq @myGraph.graph
    end

    it "instantiate EdgeCollection" do
      @myTraversal.collection = @myEdgeCollection
      expect(@myTraversal.collection.name).to eq @myEdgeCollection.collection
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
