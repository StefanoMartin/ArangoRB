require_relative './../../spec_helper'

describe ArangoTransaction do
  context "#new and use" do
    it "create new instance" do
      myArangoTransaction = ArangoTransaction.new action: "function(){ var db = require('@arangodb').db; db.MyCollection.save({}); return db.MyCollection.count(); }", write: @myCollection
      expect(myArangoTransaction.collections["write"][0]).to eq "MyCollection"
    end

    it "execute" do
      myArangoTransaction = ArangoTransaction.new action: "function(){ var db = require('@arangodb').db; db.MyCollection.save({}); return db.MyCollection.count(); }", write: @myCollection
      expect(myArangoTransaction.execute).to be >= 1
    end
  end
end
