require_relative './../../spec_helper'

describe Arango::Document do
  context "#new" do
    it "create a new Document instance without global" do
      myDocument = @myCollection.document name: "myKey"
      expect(myDocument.collection.name).to eq "MyCollection"
    end

    it "create a new Edge instance" do
      a = @myCollection.document(name: "myA", body: {"Hello": "World"}).create
      b = @myCollection.document(name: "myB", body: {"Hello": "World"}).create
      myEdgeDocument = @myEdgeCollection.document(from: a, to: b)
      expect(myEdgeDocument.body[:_from]).to eq a.id
    end
  end

  context "#create" do
    it "create a new Document" do
      @myDocument.destroy
      @myDocument.body = {"Hello": "World"}
      myDocument = @myDocument.create
      expect(myDocument.body[:Hello]).to eq "World"
    end

    it "create a duplicate Document" do
      error = ""
      begin
        myDocument = @myDocument.create
      rescue Arango::ErrorDB => e
        error = e.errorNum
      end
      expect(error).to eq 1210
    end

    it "create a new Edge" do
      myDoc = @myCollection.createDocuments document: [{"A": "B", "num": 1}, {"C": "D", "num": 3}]
      myEdge = @myEdgeCollection.document from: myDoc[0].id, to: myDoc[1].id
      myEdge = myEdge.create
      expect(myEdge.body[:_from]).to eq myDoc[0].id
    end
  end

  context "#info" do
    it "retrieve Document" do
      myDocument = @myDocument.retrieve
      expect(myDocument.body[:Hello]).to eq "World"
    end

    it "retrieve Document as Hash" do
      @server.return_output = true
      myDocument = @myDocument.retrieve
      expect(myDocument.class).to be Hash
      @server.return_output = false
      myDocument = @myDocument.retrieve
      expect(myDocument.class).to be Arango::Document
    end

    it "retrieve Edges" do
      @myEdgeCollection.createEdges from: ["MyCollection/myA", "MyCollection/myB"],
        to: @myDocument
      myEdges = @myDocument.edges(collection: @myEdgeCollection)
      expect(myEdges.length).to eq 2
    end

    it "going in different directions" do
      myDocument = @myDocument.in("MyEdgeCollection")[0].from.out(@myEdgeCollection)[0].to
      expect(myDocument.id).to eq @myDocument.id
    end
  end

  context "#modify" do
    it "replace" do
      myDocument = @myDocument.replace body: {"value": 3}
      expect(myDocument.body[:value]).to eq 3
    end

    it "update" do
      myDocument = @myDocument.update body: {"time": 13}
      expect(myDocument.body[:value]).to eq 3
    end
  end

  context "#destroy" do
    it "delete a Document" do
      result = @myDocument.destroy
      expect(result).to eq true
    end
  end
end
