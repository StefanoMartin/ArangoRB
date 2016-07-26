require 'spec_helper'

describe ArangoS do
  context "setup a global database" do
    it "setup a global database" do
      ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
      ArangoS.database = "myDatabase"
      expect(ArangoS.database).to eq "myDatabase"
    end
  end
end
