require_relative './../../spec_helper'

describe Arango::Cache do
  context "#new" do
    it "create two different documents" do
      @server.active_cache = false
      myDocument1 = @myCollection.document(name: "myKey")
      myDocument2 = @myCollection.document(name: "myKey")
      expect(myDocument1).not_to eq myDocument2
    end

    it "create same documents" do
      @server.active_cache = true
      myDocument1 = @myCollection.document(name: "myKey")
      myDocument2 = @myCollection.document(name: "myKey")
      expect(myDocument1).to eq myDocument2
    end

    it "can retrieve the cache" do
      cache = @server.cache
      expect(cache.to_h.class).to be Hash
      expect(cache.cache.class).to be Hash
      expect(cache.max.class).to be Hash
    end

    it "create two different documents" do
      @server.active_cache = false
      myDocument1 = @myCollection.document(name: "myKey")
      myDocument2 = @myCollection.document(name: "myKey")
      expect(myDocument1).not_to eq myDocument2
    end
  end
end
