require_relative './../../spec_helper'

describe ArangoEdge do
  context "#new" do
    it "create a new Edge instance" do
      a = ArangoVertex.new(key: "myA", body: {"Hello" => "World"}).create
      b = ArangoVertex.new(key: "myB", body: {"Hello" => "World"}).create
      myEdgeDocument = ArangoEdge.new collection: "MyEdgeCollection", from: a, to: b
      expect(myEdgeDocument.body["_from"]).to eq a.id
    end
  end

  context "#create" do
    it "create a new Edge" do
      myDoc = @myCollection.create_document document: [{"A" => "B", "num" => 1}, {"C" => "D", "num" => 3}]
      myEdge = ArangoEdge.new from: myDoc[0].id, to: myDoc[1].id, collection: "MyEdgeCollection"
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
      a = ArangoVertex.new(body: {"Hello" => "World"}).create
      b = ArangoVertex.new(body: {"Hello" => "World!!"}).create
      myDocument = @myEdge.replace body: {"_from" => a.id, "_to" => b.id}
      expect(myDocument.body["_from"]).to eq a.id
    end

    it "update" do
      cc = ArangoVertex.new(body: {"Hello" => "World!!!"}).create
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
