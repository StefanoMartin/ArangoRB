require_relative './../../spec_helper'

describe Arango::Vertex do
  context "#new" do
    it "create a new Document instance without global" do
      myVertex = @myCollection.vertex
      expect(myVertex.collection.name).to eq "MyCollection"
    end

    it "create a new instance with global" do
      myVertex = ArangoVertex.new key: "myKey", body: {"Hello" => "World"}
      expect(myVertex.key).to eq "myKey"
    end
  end

  context "#create" do
    it "create a new Document" do
      @myVertex.destroy
      myVertex = @myVertex.create
      expect(myVertex.body["Hello"]).to eq "World"
    end

    it "create a duplicate Document" do
      myVertex = @myVertex.create
      expect(myVertex).to eq "unique constraint violated - in index 0 of type primary over [\"_key\"]"
    end
  end

  context "#info" do
    it "retrieve Document" do
      myVertex = @myVertex.retrieve
      expect(myVertex.body["Hello"]).to eq "World"
    end

    it "retrieve Edges" do
      @myEdgeCollection.create_edges from: ["MyCollection/myA", "MyCollection/myB"], to: @myVertex
      myEdges = @myVertex.retrieve_edges(collection: @myEdgeCollection)
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
