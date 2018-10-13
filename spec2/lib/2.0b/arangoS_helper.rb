require_relative './../../spec_helper'

describe Arango::Server do
  context "#general" do
    it "address" do
      @server.verbose = true
      expect(@server.base_uri).to eq "localhost:8529"
    end

    it "username" do
      expect(@server.username).to eq "root"
    end
  end

  context "#user" do
    it "setup an user" do
      user = @server.user name: "MyUser2"
      expect(user.name).to eq "MyUser2"
    end
  end

  context "#monitoring" do
    it "log" do
      expect(@server.log["totalAmount"]).to be >= 0
    end

    it "reload" do
      expect(@server.reload).to be true
    end

    it "statistics" do
      expect(@server.statistics["enabled"]).to be true
    end

    it "statisticsDescription" do
      expect(@server.statisticsDescription["groups"][0].nil?).to be false
    end

    it "role" do
      expect(@server.role).to eq "SINGLE"
    end

    # it "server" do # BUGGED
    #   expect(@server.serverData.class).to eq String
    # end


    # it "clusterStatistics" do
    #   expect(@server.clusterStatistics.class).to eq String
    # end
  end

  context "#lists" do
    it "endpoints" do
      binding.pry
      expect(@server.endpoints[0].keys[0]).to eq "endpoint"
    end

    it "users" do
      binding.pry
      expect(@server.users[0].class).to be Arango::User
    end

    it "databases" do
      expect(@server.databases[0].class).to be Arango::Database
    end
  end

  context "#async" do
    it "create async" do
      @server.async = "store"
      expect(@server.async).to eq "store"
    end

    it "pendingAsync" do
      @server.async = "store"
      @myAQL.execute
        binding.pry
      expect(@server.retrievePendingAsync).to eq []
    end

    it "fetchAsync" do
      @server.async = "store"
      id = @myAQL.execute
      expect(@server.fetchAsync(id: id)["count"]).to eq 18
    end

    it "cancelAsync" do
      @server.async = "store"
      id =  @myAQL.execute
      expect(@server.cancelAsync(id: id)).to eq "not found"
    end

    it "destroyAsync" do
      @server.async = "store"
      id =  @myAQL.execute
      expect(@server.destroyAsync type: id).to be true
    end
  end

  context "#batch" do
    it "batch" do
      @server.async = false
      @myCollection.create
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
      expect((@server.batch queries: queries).class).to be String
    end

    it "createDumpBatch" do
      expect((@server.createDumpBatch ttl: 100).to_i).to be > 1
    end

    it "prolongDumpBatch" do
      dumpBatchID = @server.createDumpBatch ttl: 100
      expect((@server.prolongDumpBatch ttl: 100, id: dumpBatchID).to_i).to be > 1
    end

    it "destroyDumpBatch" do
      dumpBatchID = @server.createDumpBatch ttl: 100
      expect(@server.destroyDumpBatch id: dumpBatchID).to be true
    end
  end

  context "#task" do
    it "tasks" do
      result = @server.tasks
      expect(result[0].id.class).to be String
    end
  end

  context "#miscellaneous" do
    it "version" do
      expect(@server.version["server"]).to eq "arango"
    end

    it "propertyWAL" do
      @server.changePropertyWAL historicLogfiles: 14
      expect(@server.propertyWAL["historicLogfiles"]).to eq 14
    end

    it "flushWAL" do
      expect(@server.flushWAL).to be true
    end

    it "transactions" do
      expect(ArangoServer.transactions["runningTransactions"]).to be >= 0
    end

    it "time" do
      expect(ArangoServer.time.class).to be Float
    end

    it "echo" do
      expect(ArangoServer.echo["user"]).to eq "root"
    end

    it "databaseVersion" do
      expect(ArangoServer.databaseVersion.to_i).to be >= 1
    end

    it "sleep" do
      expect(ArangoServer.sleep duration: 10).to be >= 1
    end

    # it "shutdown" do
    #   result = ArangoServer.shutdown
    #   `sudo service arangodb restart`
    #   expect(result).to eq "OK"
    # end
  end


end
