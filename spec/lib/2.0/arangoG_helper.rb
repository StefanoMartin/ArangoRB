require_relative './../../spec_helper'

describe Arango::Graph do
  context "#new" do
    it "create a new Graph instance without global" do
      myGraph = @myDatabase.graph name: "MyGraph"
      expect(myGraph.name).to eq "MyGraph"
    end
  end

  context "#create" do
    it "create new graph" do
      @myGraph.destroy
      @myGraph.edgeDefinitions = []
      @myGraph.orphanCollections = [@myCollection]
      myGraph = @myGraph.create
      expect(myGraph.name).to eq "MyGraph"
    end
  end

  context "#info" do
    it "info graph" do
      myGraph = @myGraph.retrieve
      expect(myGraph.name).to eq "MyGraph"
    end
  end

  context "#manageVertexCollections" do
    it "add VertexCollection" do
      errors = []
      begin
        @myGraph.removeEdgeDefinition collection: "MyEdgeCollection"
      rescue Arango::Error => e
        errors << e.errorNum
      end
      error = ""
      begin
        myGraph = @myGraph.addVertexCollection collection: "MyCollection"
      rescue Arango::ErrorDB => e
        errors << e.errorNum
      end
      @myGraph.removeVertexCollection collection: "MyCollection"
      myGraph = @myGraph.addVertexCollection collection: "MyCollection"
      expect([myGraph.orphanCollections[0].name, errors]).to eq ["MyCollection", [1930, 1938]]
    end

    it "retrieve VertexCollection" do
      myGraph = @myGraph.vertexCollections
      expect(myGraph[0].name).to eq "MyCollection"
    end

    it "remove VertexCollection" do
      myGraph = @myGraph.removeVertexCollection collection: "MyCollection"
      expect(myGraph.orphanCollections[0]).to eq nil
    end
  end

  context "#manageEdgeCollections" do
    it "add EdgeCollection" do
      myGraph = @myGraph.addEdgeDefinition collection: "MyEdgeCollection", from: "MyCollection", to: @myCollectionB
      expect(myGraph.edgeDefinitions[0][:from][0].name).to eq "MyCollection"
    end

    it "retrieve EdgeCollection" do
      myGraph = @myGraph.getEdgeCollections
      expect(myGraph[0].name).to eq "MyEdgeCollection"
    end

    it "retrieve EdgeCollection" do
      myGraph = @myGraph.edgeDefinitions
      expect(myGraph[0][:collection].name).to eq "MyEdgeCollection"
    end

    it "replace EdgeCollection" do
      myGraph = @myGraph.replaceEdgeDefinition collection: @myEdgeCollection, from: "MyCollection", to: "MyCollection"
      expect(myGraph.edgeDefinitions[0][:to][0].name).to eq "MyCollection"
    end

    it "remove EdgeCollection" do
      myGraph = @myGraph.removeEdgeDefinition collection: "MyEdgeCollection"
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
