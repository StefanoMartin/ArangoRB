require_relative './../../spec_helper'

describe ArangoDatabase do
#   context "#async" do
#     it "pendingAsync" do
#       ArangoServer.async = "store"
#       ArangoAQL.new(query: "FOR u IN MyCollection RETURN u.num").execute
#       expect(@myDatabase.pendingAsync).to eq []
#     end
#
#     it "fetchAsync" do
#       ArangoServer.async = "store"
#       id = ArangoAQL.new(query: "FOR u IN MyCollection RETURN u.num").execute
#       expect(@myDatabase.fetchAsync(id: id)["count"]).to eq 18
#     end
#
#     it "retrieveAsync" do
#       ArangoServer.async = "store"
#       ArangoAQL.new(query: "FOR u IN MyCollection RETURN u.num").execute
#       expect(@myDatabase.retrievePendingAsync).to eq []
#     end
#
#     it "cancelAsync" do
#       ArangoServer.async = "store"
#       id = ArangoAQL.new(query: "FOR u IN MyCollection RETURN u.num").execute
#       expect(@myDatabase.cancelAsync(id: id)).to eq "not found"
#     end
#
#     it "destroyAsync" do
#       ArangoServer.async = "store"
#       id = ArangoAQL.new(query: "FOR u IN MyCollection RETURN u.num").execute
#       expect(@myDatabase.destroyAsync type: id).to be true
#     end
#   end
# end

  context "#replication" do
    it "inventory" do
      expect(@myDatabase.inventory["collections"].class).to be Array
    end

    it "clusterInventory" do
      expect(@myDatabase.clusterInventory).to eq "this operation is only valid on a coordinator in a cluster"
    end

    it "logger" do
      expect(@myDatabase.logger["state"]["running"]).to be true
    end

    it "lastLogger" do
      expect(@myDatabase.loggerFollow.class).to be String
    end

    it "fistTick" do
      expect(@myDatabase.firstTick.to_i).to be >= 1
    end

    it "rangeTick" do
      expect(@myDatabase.rangeTick[0]["datafile"].class).to be String
    end

    it "configurationReplication" do
      expect(@myDatabase.configurationReplication["requestTimeout"]).to eq 600
    end

    it "modifyConfigurationReplication" do
      result = @myDatabase.modifyConfigurationReplication autoStart: true
      expect(result["autoStart"]).to be true
    end
  end

  context "#user" do
    it "grant" do
      expect(@myDatabase.grant user: @myUser).to be true
    end

    it "revoke" do
      expect(@myDatabase.revoke user: @myUser).to be true
    end
  end
end
