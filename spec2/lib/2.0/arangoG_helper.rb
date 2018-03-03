require_relative './../../spec_helper'

describe Arango::Graph do
  context "#new" do
    it "create a new Graph instance without global" do
      myGraph = @myDatabase.graph name: "MyGraph"
      expect(myGraph.graph).to eq "MyGraph"
    end
  end

  context "#create" do
    it "create new graph" do
      @myGraph.destroy
      myGraph = @myGraph.create
      expect(myGraph.graph).to eq "MyGraph"
    end
  end

  context "#info" do
    it "info graph" do
      myGraph = @myGraph.retrieve
      expect(myGraph.graph).to eq "MyGraph"
    end
  end

  context "#manageVertexCollections" do
    it "add VertexCollection" do
      @myGraph.removeEdgeCollection collection: "MyEdgeCollection"
      @myGraph.removeVertexCollection collection: "MyCollection"
      myGraph = @myGraph.addVertexCollection collection: "MyCollection"
      expect(myGraph.orphanCollections[0]).to eq "MyCollection"
    end

    it "retrieve VertexCollection" do
      myGraph = @myGraph.vertexCollections
      expect(myGraph[0].collection).to eq "MyCollection"
    end

    it "remove VertexCollection" do
      myGraph = @myGraph.removeVertexCollection collection: "MyCollection"
      expect(myGraph.orphanCollections[0]).to eq nil
    end
  end

  context "#manageEdgeCollections" do
    it "add EdgeCollection" do
      myGraph = @myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: @myCollectionB
      expect(myGraph.edgeDefinitions[0]["from"][0]).to eq "MyCollection"
    end

    it "retrieve EdgeCollection" do
      myGraph = @myGraph.edgeCollections
      expect(myGraph[0].collection).to eq "MyEdgeCollection"
    end

    it "replace EdgeCollection" do
      myGraph = @myGraph.replaceEdgeCollection collection: @myEdgeCollection, from: "MyCollection", to: "MyCollection"
      expect(myGraph.edgeDefinitions[0]["to"][0]).to eq "MyCollection"
    end

    it "remove EdgeCollection" do
      myGraph = @myGraph.removeEdgeCollection collection: "MyEdgeCollection"
      expect(myGraph.edgeDefinitions[0]).to eq nil
    end
  end

  context "#destroy" do
    it "delete graph" do
      myGraph = @myGraph.destroy
      expect(myGraph).to be true
    end
  end
end
