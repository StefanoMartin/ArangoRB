require_relative './../../spec_helper'

describe Arango::AQL do
  context "#new" do
    it "create a new AQL instance" do
      myAQL = @myDatabase.aql query: "FOR u IN MyCollection RETURN u.num"
      expect(myAQL.query).to eq "FOR u IN MyCollection RETURN u.num"
    end

    it "instantiate size" do
      @myAQL.size = 5
      expect(@myAQL.size).to eq 5
    end
  end

  context "#execute" do
    it "execute Transaction" do
      @myAQL.execute
      expect(@myAQL.result.length).to eq 5
    end

    it "execute again Transaction" do
      @myAQL.next
      expect(@myAQL.result.length).to eq 5
    end
  end

  context "#info" do
    it "explain" do
      expect(@myAQL.explain["cacheable"]).to be true
    end

    it "parse" do
      expect(@myAQL.parse["parsed"]).to be true
    end

    it "properties" do
      expect(@myAQL.properties["enabled"]).to be true
    end

    it "current" do
      expect(@myAQL.current).to eq []
    end

    it "slow" do
      expect(@myAQL.slow).to eq []
    end
  end

  context "#delete" do
    it "stopSlow" do
      expect(@myAQL.stopSlow).to be true
    end

    it "kill" do
      expect(@myAQL.kill.class).to be String
    end

    it "changeProperties" do
      result = @myDatabase.change_query_properties maxSlowQueries: 65
      expect(result["maxSlowQueries"]).to eq 65
    end
  end
end
