require_relative './../../spec_helper'

describe Arango::User do
  context "#new" do
    it "create a new User without global" do
      myUser = @server.user name: "MyUser2", password: "Test"
      expect(myUser.user).to eq "MyUser2"
    end
  end

  context "#create" do
    it "create a new user" do
      @myUser.destroy
      @myUser = @server.user name: "MyUser", password: "Test"
      result = @myUser.create
      expect(result.user).to eq "MyUser"
    end

    it "create a duplicate user" do
      begin
        @myUser.create
      rescue Arango::Error => e
        result = e.message
      end
      expect(result).to eq "duplicate user"
    end
  end
  #
  context "#info" do
    it "retrieve User" do
      myUser = @myUser.retrieve
      expect(myUser.active).to be true
    end
  end

  context "#database" do
    it "grant" do
      result = @myUser.addDatabaseAccess grant: "rw", database: @myDatabase
      expect(result).to eq "rw"
    end

    it "databases" do
      result = @myUser.listAccess
      expect(result[:MyDatabase]).to eq "rw"
    end

    it "revoke" do
      result = @myUser.revokeDatabaseAccess database: @myDatabase
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
