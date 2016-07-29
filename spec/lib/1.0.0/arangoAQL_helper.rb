require_relative './../../spec_helper'

describe ArangoT do
  # before :all do
  #   ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
  #   ArangoS.database = "MyDatabase"
  #   ArangoS.collection = "MyCollection"
  #   ArangoS.graph = "MyGraph"
  #   ArangoDB.new.create
  #   @myGraph = ArangoG.new.create
  #   @myCollection = ArangoC.new.create
  #   @myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
  #   @myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
  #   @myAQL = ArangoAQL.new query: "FOR u IN MyCollection RETURN u.num"
  #   @myDoc = @myCollection.create_document document: [{"num" => 1, "_key" => "FirstKey"}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 2}, {"num" => 2}, {"num" => 2}, {"num" => 3}, {"num" => 2}, {"num" => 5}, {"num" => 2}]
  #   @myEdgeCollection.create_edge from: [@myDoc[0].id, @myDoc[1].id, @myDoc[2].id, @myDoc[3].id, @myDoc[7].id], to: [@myDoc[4].id, @myDoc[5].id, @myDoc[6].id, @myDoc[8].id]
  # end
  #
  # after :all do
  #   ArangoDB.new.destroy
  # end

  context "#new" do
    it "create a new AQL instance" do
      myAQL = ArangoAQL.new query: "FOR u IN MyCollection RETURN u.num"
      expect(myAQL.query).to eq "FOR u IN MyCollection RETURN u.num"
    end

    it "instantiate size" do
      @myAQL.size = 5
      expect(@myAQL.size).to eq 5
    end
  end

  context "#execute" do
    it "execute Transaction" do
      @myAQL.execute
      expect(@myAQL.result.length).to eq 5
    end

    it "execute again Transaction" do
      @myAQL.next
      expect(@myAQL.result.length).to eq 5
    end
  end

  context "#info" do
    it "explain" do
      expect(@myAQL.explain["cacheable"]).to be true
    end

    it "parse" do
      expect(@myAQL.parse["parsed"]).to be true
    end

    it "properties" do
      expect(@myAQL.properties["enabled"]).to be true
    end

    it "current" do
      expect(@myAQL.current).to eq []
    end

    it "slow" do
      expect(@myAQL.slow).to eq []
    end
  end

  context "#delete" do
    it "stopSlow" do
      expect(@myAQL.stopSlow).to be true
    end

    it "kill" do
      expect(@myAQL.kill.class).to be String
    end

    it "changeProperties" do
      result = @myAQL.changeProperties maxSlowQueries: 65
      expect(result["maxSlowQueries"]).to eq 65
    end
  end
end
