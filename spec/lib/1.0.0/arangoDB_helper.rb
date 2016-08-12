require_relative './../../spec_helper'

describe ArangoDatabase do
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
