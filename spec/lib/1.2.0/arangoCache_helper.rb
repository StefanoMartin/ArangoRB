require_relative './../../spec_helper'

describe ArangoCache do
  context "#cache" do
    it "cache" do
      @myDatabase.retrieve
      @myCollection.retrieve
      @myEdgeCollection.retrieve
      @myGraph.retrieve
      @myAQL.execute
      @myVertex.retrieve
      @myEdge.retrieve
      @myIndex.retrieve
      @myUser.retrieve
      @myTask.retrieve
      val = ArangoCache.cache data: [@myDatabase, @myCollection, @myEdgeCollection, @myGraph, @myAQL, @myVertex, @myEdge, @myIndex, @myUser, @myTask, [1,2,3]]
      expect(val.length).to eq 11
    end

    it "cache with ID" do
      myAQL2 = ArangoAQL.new query: "FOR u IN MyCollection RETURN u"
      myAQL2.execute
      ArangoCache.cache id: "myAQL", data: myAQL2
      val = ArangoCache.uncache type: "AQL", id: "myAQL"
      expect(val.result.length).to be > 0
    end

    it "uncache" do
      val = ArangoCache.uncache data: [@myCollection, @myVertex]
      val = val.map{|v| v.class.to_s}
      expect(val).to eq ["ArangoCollection", "ArangoVertex"]
    end
  end

  context "#limits" do
    it "max" do
      ArangoCache.cache data: @myDoc
      val = ArangoCache.retrieve["Document"]
      ArangoCache.max type: "Document", val: 5
      ArangoCache.retrieve["Document"]
      ArangoCache.cache data: @myDoc[0]
      val = ArangoCache.uncache type: "Document"
      expect(val.length).to eq 5
    end
  end

  context "#clear" do
    it "clear object" do
      ArangoCache.clear data: @myCollection
      val = ArangoCache.uncache data: @myCollection
      expect(val.nil?).to be true
    end

    it "clear type" do
      ArangoCache.clear type: "Vertex"
      val = ArangoCache.retrieve
      expect(val["Vertex"].empty?).to be true
    end

    it "clear type" do
      ArangoCache.clear
      val = ArangoCache.retrieve
      expect(val["Database"].empty?).to be true
    end
  end
end
