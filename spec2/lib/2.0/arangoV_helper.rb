require_relative './../../spec_helper'

describe Arango::Vertex do
  context "#new" do
    it "create a new Document instance" do
      myVertex = @myCollection.vertex
      expect(myVertex.collection.name).to eq "MyCollection"
    end
  end

  context "#create" do
    it "create a new Document" do
      @myVertex.destroy
      myVertex = @myVertex.create
      expect(myVertex.body["Hello"]).to eq "World"
    end

    it "create a duplicate Document" do
      error = ""
      begin
        myVertex = @myVertex.create
      rescue Arango::ErrorDB => e
        error = e.errorNum
      end
      expect(error).to eq 1210
    end
  end

  context "#info" do
    it "retrieve Document" do
      myVertex = @myVertex.retrieve
      expect(myVertex.body["Hello"]).to eq "World"
    end

    it "retrieve Edges" do
      @myEdgeCollection.createEdges from: ["MyCollection/myA", "MyCollection/myB"], to: @myVertex
      myEdges = @myVertex.edges(@myEdgeCollection)
      expect(myEdges.length).to eq 2
    end

    it "going in different directions" do
      myVertex = @myVertex.in("MyEdgeCollection")[0].from.out(@myEdgeCollection)[0].to
      expect(myVertex.id).to eq @myVertex.id
    end
  end

  context "#modify" do
    it "replace" do
      myVertex = @myVertex.replace body: {"value" => 3}
      expect(myVertex.body["value"]).to eq 3
    end

    it "update" do
      myVertex = @myVertex.update body: {"time" => 13}
      expect(myVertex.body["value"]).to eq 3
    end
  end

  context "#destroy" do
    it "delete a Document" do
      result = @myVertex.destroy
      expect(result).to eq true
    end
  end
end
