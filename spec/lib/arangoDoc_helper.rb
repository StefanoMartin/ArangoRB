require_relative './../spec_helper'

describe ArangoDoc do
  before :all do
    ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
    ArangoS.database = "MyDatabase"
    ArangoS.collection = "MyCollection"
    ArangoDB.new.create
    @myCollection = ArangoC.new.create
    @myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
    @myDocument = ArangoDoc.new body: {"Hello" => "World", "num" => 1}, key: "FirstDocument"
  end

  after :all do
    ArangoDB.new.destroy
  end

  context "#new" do
    it "create a new Document instance without global" do
      myDocument = ArangoDoc.new collection: "MyCollection", database: "MyDatabase"
      expect(myDocument.collection).to eq "MyCollection"
    end

    it "create a new instance with global" do
      myDocument = ArangoDoc.new key: "myKey", body: {"Hello" => "World"}
      expect(myDocument.key).to eq "myKey"
    end

    it "create a new Edge instance" do
      a = ArangoDoc.new(key: "myA", body: {"Hello" => "World"}).create
      b = ArangoDoc.new(key: "myB", body: {"Hello" => "World"}).create
      myEdgeDocument = ArangoDoc.new collection: "MyEdgeCollection", from: a, to: b
      expect(myEdgeDocument.body["_from"]).to eq a.id
    end
  end

  context "#create" do
    it "create a new Document" do
      myDocument = @myDocument.create
      expect(myDocument.body["Hello"]).to eq "World"
    end

    it "create a duplicate Document" do
      myDocument = @myDocument.create
      expect(myDocument).to eq "cannot create document, unique constraint violated"
    end

    it "create a new Edge" do
      myDoc = @myCollection.create_document document: [{"A" => "B", "num" => 1}, {"C" => "D", "num" => 3}]
      myEdge = ArangoDoc.new collection: "MyEdgeCollection", from: myDoc[0].id, to: myDoc[1].id
      myEdge = myEdge.create
      expect(myEdge.body["_from"]).to eq myDoc[0].id
    end
  end

  context "#info" do
    it "retrieve Document" do
      myDocument = @myDocument.retrieve
      expect(myDocument.body["Hello"]).to eq "World"
    end

    it "retrieve Edges" do
      testmy = @myEdgeCollection.create_edge from: ["MyCollection/myA", "MyCollection/myB"], to: @myDocument
      myEdges = @myDocument.retrieve_edges(collection: @myEdgeCollection)
      expect(myEdges.length).to eq 2
    end

    it "going in different directions" do
      myDocument = @myDocument.in("MyEdgeCollection")[0].from.out(@myEdgeCollection)[0].to
      expect(myDocument.id).to eq @myDocument.id
    end
  end

  context "#modify" do
    it "replace" do
      myDocument = @myDocument.replace body: {"value" => 3}
      expect(myDocument.body["value"]).to eq 3
    end

    it "update" do
      myDocument = @myDocument.update body: {"time" => 13}
      expect(myDocument.body["value"]).to eq 3
    end
  end

  context "#destroy" do
    it "delete a Document" do
      result = @myDocument.destroy
      expect(result).to eq true
    end
  end
end
