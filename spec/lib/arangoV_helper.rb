require_relative './../spec_helper'

describe ArangoV do
  before :all do
    ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
    ArangoS.database = "MyDatabase"
    ArangoS.collection = "MyCollection"
    ArangoS.graph = "MyGraph"
    ArangoDB.new.create
    @myGraph = ArangoG.new.create
    @myCollection = ArangoC.new.create
    @myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
    @myVertex = ArangoV.new body: {"Hello" => "World", "num" => 1}, key: "FirstDocument"
    @myGraph.addVertexCollection collection: "MyCollection"
  end

  after :all do
    ArangoDB.new.destroy
  end

  context "#new" do
    it "create a new Document instance without global" do
      myVertex = ArangoV.new collection: "MyCollection", database: "MyDatabase", graph: "MyGraph"
      expect(myVertex.collection).to eq "MyCollection"
    end

    it "create a new instance with global" do
      myVertex = ArangoV.new key: "myKey", body: {"Hello" => "World"}
      expect(myVertex.key).to eq "myKey"
    end
  end

  context "#create" do
    it "create a new Document" do
      myVertex = @myVertex.create
      expect(myVertex.body["Hello"]).to eq "World"
    end

    it "create a duplicate Document" do
      myVertex = @myVertex.create
      expect(myVertex).to eq "unique constraint violated"
    end
  end

  context "#info" do
    it "retrieve Document" do
      myVertex = @myVertex.retrieve
      expect(myVertex.body["Hello"]).to eq "World"
    end

    it "retrieve Edges" do
      testmy = @myEdgeCollection.create_edge from: ["MyCollection/myA", "MyCollection/myB"], to: @myVertex
      myEdges = @myVertex.retrieve_edges(collection: @myEdgeCollection)
      expect(myEdges.length).to eq 2
    end

    # it "going in different directions" do
    #   myVertex = @myVertex.in("MyEdgeCollection")[0].from.out(@myEdgeCollection)[0].to
    #   expect(myVertex.id).to eq @myVertex.id
    # end
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
