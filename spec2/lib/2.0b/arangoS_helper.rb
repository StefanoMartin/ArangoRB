require_relative './../../spec_helper'

describe Arango::Server do
  context "#general" do
    it "address" do
      @server.verbose = true
      expect(@server.base_uri).to eq "http://localhost:8529"
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
      expect(@server.log[:totalAmount]).to be >= 0
    end

    it "reload" do
      expect(@server.reload).to be true
    end

    it "statistics" do
      expect(@server.statistics[:enabled]).to be true
    end

    it "statisticsDescription" do
      expect(@server.statisticsDescription[:groups][0].nil?).to be false
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
    # it "endpoints" do
    #   expect(@server.endpoints[0].keys[0]).to eq "endpoint"
    # end

    it "users" do
      expect(@server.users[0].class).to be Arango::User
    end

    it "databases" do
      expect(@server.databases[0].class).to be Arango::Database
    end
  end

  context "#async" do
    it "create async" do
      @server.async = :store
      expect(@server.async).to eq :store
    end

    it "pendingAsync" do
      @server.async = :store
      @myAQL.execute
      val = @server.retrievePendingAsync
      expect(val.to_i.to_s).to eq val
    end

    it "fetchAsync" do
      @server.async = :store
      id = @myAQL.execute
      @server.async = false
      val = @server.fetchAsync(id: id)
      expect(val[:result]).to eq [1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 2, 5, 2, 1, 1, 2]
    end

    it "cancelAsync" do
      @server.async = :store
      id = @myAQL.execute
      @server.async = false
      val = @server.cancelAsync(id: id)
      expect(val).to eq true
    end

    it "destroyAsync" do
      @server.async = :store
      id = @myAQL.execute
      @server.async = false
      val = @server.destroyAsync id: id
      expect(val).to be true
    end
  end

  context "#batch" do
    it "batch" do
      @server.async = false
      queries = [{
        "method": "POST",
        "address": "/_db/MyDatabase/_api/collection",
        "body": {"name": "newCOLLECTION"},
        "id": "1"
      },
      {
        "method": "GET",
        "address": "/_api/database",
        "id": "2"
      }]
      val = @server.batch queries: queries
      expect(val.class).to be Arango::Batch
      response = val.execute
      expect(response.class).to be String
    end

    it "createDumpBatch" do
      expect((@server.createDumpBatch ttl: 100).to_i).to be > 1
    end

    it "prolongDumpBatch" do
      dumpBatchID = @server.createDumpBatch ttl: 100
      val = @server.prolongDumpBatch ttl: 100, id: dumpBatchID
      expect(val).to be true
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
      expect(@server.version[:server]).to eq "arango"
    end

    # it "propertyWAL" do
    #   @server.changePropertyWAL historicLogfiles: 14
    #   val = @server.propertyWAL[:historicLogfiles]
    #   expect(val).to eq 14
    # end

    it "flushWAL" do
      expect(@server.flushWAL).to be true
    end

    it "transactions" do
      expect(@server.transactions[:runningTransactions]).to be >= 0
    end

    it "time" do
      expect([BigDecimal, Float].include?(@server.time.class)).to eq true
    end

    it "echo" do
      expect(@server.echo[:user]).to eq "root"
    end

    it "databaseVersion" do
      expect(@server.databaseVersion.to_i).to be >= 1
    end

    # it "sleep" do
    #   expect(@server.sleep duration: 10).to be >= 1
    # end

    # it "shutdown" do
    #   result = ArangoServer.shutdown
    #   `sudo service arangodb restart`
    #   expect(result).to eq "OK"
    # end
  end


end
