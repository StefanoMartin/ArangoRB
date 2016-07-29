require_relative './../../spec_helper'

describe ArangoG do
  # before :all do
  #   ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
  #   ArangoS.database = "MyDatabase"
  #   ArangoS.collection = "MyCollection"
  #   ArangoDB.new.create
  #   @myCollection = ArangoC.new.create
  #   @myCollectionB = ArangoC.new(collection: "MyCollectionB").create
  #   @myCollectionC = ArangoC.new(collection: "MyCollectionC").create
  #   @myCollectionD = ArangoC.new(collection: "MyCollectionD").create
  #   @myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
  #   @myGraph = ArangoG.new graph: "MyGraph"
  # end
  #
  # after :all do
  #   ArangoDB.new.destroy
  # end

  context "#new" do
    it "create a new Graph instance without global" do
      myGraph = ArangoG.new graph: "MyGraph", database: "MyDatabase"
      expect(myGraph.graph).to eq "MyGraph"
    end

    it "create a new instance with global" do
      myGraph = ArangoG.new
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
