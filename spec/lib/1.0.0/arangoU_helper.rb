require_relative './../../spec_helper'

describe ArangoUser do
  context "#new" do
    it "create a new User without global" do
      myUser = ArangoUser.new user: "MyUser2", password: "Test"
      expect(myUser.user).to eq "MyUser2"
    end

    it "create a new instance with global" do
      myUser = ArangoUser.new
      expect(myUser.user).to eq "MyUser"
    end
  end

  context "#create" do
    it "create a new user" do
      @myUser.destroy
      @myUser = ArangoUser.new user: "MyUser", password: "Test"
      result = @myUser.create
      print result
      expect(result.user).to eq "MyUser"
    end

    it "create a duplicate user" do
      result = @myUser.create
      expect(result).to eq "duplicate user"
    end
  end

  context "#info" do
    it "retrieve User" do
      myUser = @myUser.retrieve
      expect(myUser.active).to be true
    end
  end

  context "#database" do
    it "grant" do
      result = @myUser.grant database: @myDatabase
      expect(result).to be true
    end

    it "databases" do
      result = @myUser.databases
      expect(result["MyDatabase"]).to eq "rw"
    end

    it "revoke" do
      result = @myUser.revoke database: @myDatabase
      expect(result).to be true
    end
  end

  context "#modify" do
    it "replace" do
      @myUser.replace active: false, password: "Test"
      expect(@myUser.active).to be false
    end

    it "update" do
      @myUser.update active: false, password: "Test"
      expect(@myUser.active).to be false
    end
  end

  context "#destroy" do
    it "destroy" do
      result = @myUser.destroy
      expect(result).to be true
    end
  end
end
