require_relative './../../spec_helper'

describe ArangoDB do
  # before :all do
  #   ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
  #   ArangoS.database = "MyDatabase"
  #   @myDatabase = ArangoDB.new
  # end

  context "#new" do
    it "create a new instance without global" do
      myDatabase = ArangoDB.new database: "MyDatabase"
      expect(myDatabase.database).to eq "MyDatabase"
    end

    it "create a new instance with global" do
      myDatabase = ArangoDB.new
      expect(myDatabase.database).to eq "MyDatabase"
    end
  end

  context "#create" do
    it "create a new Database" do
      @myDatabase.destroy
      myDatabase = @myDatabase.create
      expect(myDatabase.database).to eq "MyDatabase"
    end

    it "create a duplicate Database" do
      myDatabase = @myDatabase.create
      expect(myDatabase).to eq "duplicate name"
    end
  end

  context "#info" do
    it "obtain general info" do
      info = ArangoDB.info
      expect(info["name"]).to eq "_system"
    end

    it "list databases" do
      list = ArangoDB.databases
      expect(list.length).to be >= 1
    end

    it "list collections" do
      list = @myDatabase.collections
      expect(list.length).to be 0
    end

    it "list graphs" do
      list = @myDatabase.graphs
      expect(list.length).to be 0
    end
  end

  context "#query" do
    it "properties" do
      expect(@myDatabase.propertiesQuery["enabled"]).to be true
    end

    it "current" do
      expect(@myDatabase.currentQuery).to eq []
    end

    it "slow" do
      expect(@myDatabase.slowQuery).to eq []
    end
  end

  context "#delete query" do
    it "stopSlow" do
      expect(@myDatabase.stopSlowQuery).to be true
    end

    it "kill" do
      expect(@myDatabase.killQuery(id: "4353453463443").class).to be String
    end

    it "changeProperties" do
      result = @myDatabase.changePropertiesQuery maxSlowQueries: 65
      expect(result["maxSlowQueries"]).to eq 65
    end
  end

  context "#cache" do
    it "clear" do
      expect(@myDatabase.clearCache).to be true
    end

    it "change Property Cache" do
      @myDatabase.changePropertyCache maxResults: 130
      expect(@myDatabase.propertyCache["maxResults"]).to eq 130
    end
  end

  context "#function" do
    it "create Function" do
      result = @myDatabase.createFunction name: "myfunctions::temperature::celsiustofahrenheit", code: "function (celsius) { return celsius * 1.8 + 32; }"
      expect(result.class).to eq Hash
    end

    it "list Functions" do
      result = @myDatabase.functions
      expect(result[0]["name"]).to eq "myfunctions::temperature::celsiustofahrenheit"
    end

    it "delete Function" do
      result = @myDatabase.deleteFunction name: "myfunctions::temperature::celsiustofahrenheit"
      expect(result).to be true
    end
  end

  context "#destroy" do
    it "delete a Database" do
      myDatabase = @myDatabase.destroy
      expect(myDatabase).to be true
    end
  end
end
