require_relative './../../spec_helper'

describe Arango::Collection do
  context "#get" do
    it "revision" do
      expect(@myCollection.revision.class).to be String
    end

    it "collection" do
      expect(@myCollection.rotate).to eq "could not rotate journal: no journal"
    end
  end

  context "#import" do
    it "import" do
      attributes = ["value", "num", "name"]
      values = [["uno",1,"ONE"],["due",2,"TWO"],["tre",3,"THREE"]]
      result = @myCollection.import attributes: attributes, values: values
      expect(result[:created]).to eq 3
    end

    it "import single" do
      attributes = ["value", "num", "name"]
      values = ["uno",1,"ONE"]
      result = @myCollection.import attributes: attributes, values: values
      expect(result[:created]).to eq 1
    end

    it "importJSON" do
      body = [{"value": "uno", "num": 1, "name": "ONE"}, {"value": "due", "num": 2, "name": "DUE"}]
      result = @myCollection.importJSON body: body
      expect(result[:created]).to eq 2
    end
  end

  context "#export" do
    it "export" do
      result = @myCollection.export flush: true
      expect(result[0].class).to be Arango::Document
    end

    it "exportNext" do
      result = @myCollection.export batchSize: 3, flush: true
      result = @myCollection.exportNext
      expect(result[0].class).to be Arango::Document
    end
  end

  context "#indexes" do
    it "indexes" do
      expect(@myCollection.indexes[:indexes][0].class).to be Arango::Index
    end

    it "create" do
      myIndex = @myCollection.index(unique: false, fields: "num", type: "hash").create
      expect(myIndex.fields).to eq ["num"]
    end
  end

  context "#replication" do
    it "data" do
      expect(@myCollection.data.length).to be > 100
    end
  end
end
