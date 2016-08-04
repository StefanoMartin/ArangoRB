require_relative './../../spec_helper'

describe ArangoS do
  context "#general" do
    it "address" do
      expect(ArangoS.address).to eq "localhost:8529"
    end

    it "username" do
      expect(ArangoS.username).to eq "root"
    end
  end

  context "#user" do
    it "setup a global user" do
      ArangoS.user = "MyUser2"
      expect(ArangoS.user).to eq "MyUser2"
    end
  end

  context "#monitoring" do
    it "log" do
      expect(ArangoS.log["totalAmount"]).to be >= 0
    end

    it "reload" do
      expect(ArangoS.reload).to be true
    end

    it "statistics" do
      expect(ArangoS.statistics["enabled"]).to be true
    end

    it "statisticsDescription" do
      expect(ArangoS.statisticsDescription["groups"][0].nil?).to be false
    end

    it "role" do
      expect(ArangoS.role.class).to eq String
    end

    it "server" do
      expect(ArangoS.server.class).to eq String
    end

    it "serverID" do
      expect(ArangoS.serverId.to_i).to be >= 1
    end

    it "clusterStatistics" do
      expect(ArangoS.clusterStatistics.class).to eq String
    end
  end

  context "#endpoints" do
    it "endpoints" do
      expect(ArangoS.endpoints[0].keys[0]).to eq "endpoint"
    end

    it "users" do
      expect(ArangoS.users.length).to be >= 1
    end
  end

  context "#async" do
    it "create async" do
      ArangoS.async = "store"
      expect(ArangoS.async).to eq "store"
    end
  end

  context "#batch" do
    it "batch" do
      ArangoS.async = false
      ArangoC.new.create
      queries = [{
        "type": "POST",
        "address": "/_db/MyDatabase/_api/collection",
        "body": {"name": "newCOLLECTION"},
        "id": "1"
      },
      {
        "type": "GET",
        "address": "/_api/database",
        "id": "2"
      }]
      expect((ArangoS.batch queries: queries).class).to be String
    end

    it "createDumpBatch" do
      expect((ArangoS.createDumpBatch ttl: 100).to_i).to be > 1
    end

    it "prolongDumpBatch" do
      dumpBatchID = ArangoS.createDumpBatch ttl: 100
      expect((ArangoS.prolongDumpBatch ttl: 100, id: dumpBatchID).to_i).to be > 1
    end

    it "destroyDumpBatch" do
      dumpBatchID = ArangoS.createDumpBatch ttl: 100
      expect(ArangoS.destroyDumpBatch id: dumpBatchID).to be true
    end
  end
end
