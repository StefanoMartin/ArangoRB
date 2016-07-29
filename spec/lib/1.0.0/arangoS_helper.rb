require_relative './../../spec_helper'

describe ArangoS do
  context "#user" do
    it "setup a global user" do
      ArangoS.user = "MyUser"
      expect(ArangoS.user).to eq "MyUser"
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

end
