require_relative './../../spec_helper'

describe Arango::Database do

  context "#new" do
    it "create a new instance" do
      myDatabase = @server.database name: "MyDatabase"
      expect(myDatabase.name).to eq "MyDatabase"
    end
  end

  context "#create" do
    it "create a new Database" do
      @myDatabase.destroy
      myDatabase = @myDatabase.create
      expect(myDatabase.name).to eq "MyDatabase"
    end

    it "create a duplicate Database" do
      myDatabase = @myDatabase.create
      expect(myDatabase).to eq "duplicate name"
    end
  end

  context "#info" do
    it "obtain general info" do
      info = @myDatabase.info
      expect(info["name"]).to eq "MyDatabase"
    end

    it "list databases" do
      list = @server.databases
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
      expect(@myDatabase.stopSlowQueries).to be true
    end

    it "kill" do
      @myCollection.create
      @myCollection.createDocument document: [{"num" => 1, "_key" => "FirstKey"},
        {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1},
        {"num" => 1}, {"num" => 2}, {"num" => 2}, {"num" => 2}, {"num" => 3},
        {"num" => 2}, {"num" => 5}, {"num" => 2}]
      @myAQL.size = 3
      @myAQL.execute
      expect((@myDatabase.kill_aql query: @myAQL).split(" ")[0]).to eq "cannot"
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
      @myDatabase.changePropertyQueryCache maxResults: 130
      expect(@myDatabase.propertyQueryCache["maxResults"]).to eq 130
    end
  end

  context "#function" do
    it "create Function" do
      result = @myDatabase.createAqlFunction name: "myfunctions::temperature::celsiustofahrenheit",
      code: "function (celsius) { return celsius * 1.8 + 32; }"
      expect(result.class).to eq Hash
    end

    it "list Functions" do
      result = @myDatabase.aqlFunctions
      expect(result[0]["name"]).to eq "myfunctions::temperature::celsiustofahrenheit"
    end

    it "delete Function" do
      result = @myDatabase.deleteAqlFunction name: "myfunctions::temperature::celsiustofahrenheit"
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
