require_relative './../../spec_helper'

describe ArangoE do
  # before :all do
  #   ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
  #   ArangoS.database = "MyDatabase"
  #   ArangoS.collection = "MyCollection"
  #   ArangoS.graph = "MyGraph"
  #   ArangoDB.new.create
  #   @myGraph = ArangoG.new.create
  #   @myCollection = ArangoC.new.create
  #   @myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
  #   @myGraph.addVertexCollection collection: "MyCollection"
  #   @myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
  #   @vertexA = ArangoV.new(body: {"Hello" => "World", "num" => 1}).create
  #   @vertexB = ArangoV.new(body: {"Hello" => "Moon", "num" => 2}).create
  #   @myEdge = ArangoE.new(from: @vertexA, to: @vertexB, collection: "MyEdgeCollection").create
  # end
  #
  # after :all do
  #   ArangoDB.new.destroy
  # end

  context "#new" do
    it "create a new Edge instance" do
      a = ArangoV.new(key: "myA", body: {"Hello" => "World"}).create
      b = ArangoV.new(key: "myB", body: {"Hello" => "World"}).create
      myEdgeDocument = ArangoE.new collection: "MyEdgeCollection", from: a, to: b
      expect(myEdgeDocument.body["_from"]).to eq a.id
    end
  end

  context "#create" do
    it "create a new Edge" do
      myDoc = @myCollection.create_document document: [{"A" => "B", "num" => 1}, {"C" => "D", "num" => 3}]
      myEdge = ArangoE.new from: myDoc[0].id, to: myDoc[1].id, collection: "MyEdgeCollection"
      myEdge = myEdge.create
      expect(myEdge.body["_from"]).to eq myDoc[0].id
    end
  end

  context "#info" do
    it "retrieve Document" do
      myDocument = @myEdge.retrieve
      expect(myDocument.collection).to eq "MyEdgeCollection"
    end
  end

  context "#modify" do
    it "replace" do
      a = ArangoV.new(body: {"Hello" => "World"}).create
      b = ArangoV.new(body: {"Hello" => "World!!"}).create
      myDocument = @myEdge.replace body: {"_from" => a.id, "_to" => b.id}
      expect(myDocument.body["_from"]).to eq a.id
    end

    it "update" do
      cc = ArangoV.new(body: {"Hello" => "World!!!"}).create
      myDocument = @myEdge.update body: {"_to" => cc.id}
      expect(myDocument.body["_to"]).to eq cc.id
    end
  end

  context "#destroy" do
    it "delete a Document" do
      result = @myEdge.destroy
      expect(result).to eq true
    end
  end
end
