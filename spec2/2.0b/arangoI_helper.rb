require_relative './../../spec_helper'

describe ArangoIndex do
  context "#new" do
    it "create a new Index without global" do
      myIndex = ArangoIndex.new collection: @myCollection, database: @myDatabase, fields: "num", unique: false, id: "myIndex"
      expect(myIndex.id).to eq "myIndex"
    end

    it "create a new Index with global" do
      myIndex = ArangoIndex.new fields: "num", unique: false, id: "myIndex2"
      expect(myIndex.id).to eq "myIndex2"
    end
  end

  context "#create" do
    it "create a new Index" do
      result = @myIndex.create
      expect(result.type).to eq "hash"
    end
  end

  context "#retrieve" do
    it "retrieve an Index" do
      result = @myIndex.retrieve
      expect(result.type).to eq "hash"
    end
  end

  context "#info" do
    it "list Indexes" do
      result = ArangoIndex.indexes
      expect(result["indexes"][0].class).to be ArangoIndex
    end
  end

  context "#destroy" do
    it "destroy" do
      result = @myIndex.destroy
      expect(result).to be true
    end
  end
end
