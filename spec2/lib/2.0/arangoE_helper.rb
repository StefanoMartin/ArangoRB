require_relative './../../spec_helper'

describe ArangoEdge do
  context "#new" do
    it "create a new Edge instance" do
      a = @myCollection.vertex(name: "myA", body: {"Hello" => "World"}).create
      b = @myCollection.vertex(key: "myB", body: {"Hello" => "World"}).create
      myEdgeDocument = @myEdgeCollection.edge(from: a, to: b)
      expect(myEdgeDocument.body["_from"]).to eq a.id
    end
  end

  context "#create" do
    it "create a new Edge" do
      myDoc = @myCollection.createDocuments document: [{"A" => "B", "num" => 1},
        {"C" => "D", "num" => 3}]
      myEdge = @myEdgeCollection.edge(from: myDoc[0].id, to: myDoc[1].id)
      myEdge = myEdge.create
      expect(myEdge.body["_from"]).to eq myDoc[0].id
    end
  end

  context "#info" do
    it "retrieve Document" do
      myDocument = @myEdge.retrieve
      expect(myDocument.collection.name).to eq "MyEdgeCollection"
    end
  end

  context "#modify" do
    it "replace" do
      a = @myCollection.vertex(body: {"Hello" => "World"}).create
      b = @myCollection.vertex(body: {"Hello" => "World!!"}).create
      myDocument = @myEdge.replace body: {"_from" => a.id, "_to" => b.id}
      expect(myDocument.body["_from"]).to eq a.id
    end

    it "update" do
      cc = @myCollection.vertex(body: {"Hello" => "World!!!"}).create
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
