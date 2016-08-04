require_relative './../../spec_helper'

describe ArangoC do
  context "#get" do
    it "revision" do
      expect(@myCollection.revision.to_i).to be >= 1
    end
  end

  context "#import" do
    it "import" do
      attributes = ["value", "num", "name"]
      values = [["uno",1,"ONE"],["due",2,"TWO"],["tre",3,"THREE"]]
      result = @myCollection.import attributes: attributes, values: values
      expect(result["created"]).to eq 3
    end

    it "import single" do
      attributes = ["value", "num", "name"]
      values = ["uno",1,"ONE"]
      result = @myCollection.import attributes: attributes, values: values
      expect(result["created"]).to eq 1
    end

    it "importJSON" do
      body = [{"value": "uno", "num": 1, "name": "ONE"}, {"value": "due", "num": 2, "name": "DUE"}]
      result = @myCollection.importJSON body: body
      expect(result["created"]).to eq 2
    end
  end

  context "#export" do
    it "export" do
      result = @myCollection.export
      expect(result[0].class).to be ArangoDoc
    end

    it "exportNext" do
      result = @myCollection.export batchSize: 3
      result = @myCollection.exportNext
      expect(result[0].class).to be ArangoDoc
    end
  end

  context "#indexes" do
    it "indexes" do
      expect(@myCollection.indexes["indexes"][0].class).to be ArangoI
    end

    it "retrieve" do
      expect((@myCollection.retrieveIndex id: 0).unique).to be true
    end

    it "create" do
      myIndex = @myCollection.createIndex unique: false, fields: "num", type: "hash"
      expect(myIndex.fields).to eq ["num"]
    end

    it "delete" do
      expect(@myCollection.deleteIndex id: @myIndex.key).to eq true
    end
  end

  context "#replication" do
    it "data" do
      expect(@myCollection.data.length).to be > 100
    end
  end

end
