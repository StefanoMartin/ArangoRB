require_relative './../../spec_helper'

describe ArangoTask do
  context "#new" do
    it "create new instance" do
      myArangoTask = ArangoTask.new id: "mytaskid", name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {"foo" => "bar", "bar" => "foo"}, period: 2
      expect(myArangoTask.params["foo"]).to eq "bar"
    end
  end

  context "#create" do
    it "create a new Task instance" do
      myArangoTask = ArangoTask.new name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {"foo" => "bar", "bar" => "foo"}, period: 2
      expect(myArangoTask.create.created.class).to eq Float
    end

    it "create a new Task instance with ID" do
      myArangoTask = ArangoTask.new id: "mytaskid", name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {"foo2" => "bar2", "bar2" => "foo2"}, period: 2
      expect(myArangoTask.create.params["foo2"]).to eq "bar2"
    end

    it "duplilcate a Task instance with ID" do
      myArangoTask = ArangoTask.new id: "mytaskid", name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {"foo21" => "bar2", "bar21" => "foo21"}, period: 2
      expect(myArangoTask.create).to eq "duplicate task id"
    end
  end

  context "#retrieve" do
    it "retrieve lists" do
      myArangoTask = ArangoTask.new name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {"foo2" => "bar2", "bar2" => "foo2"}, period: 2
      myArangoTask.create
      result = ArangoTask.tasks.map{|x| x.database}
      expect(result.include? 'MyDatabase').to be true
    end

    it "retrieve" do
      myArangoTask = ArangoTask.new name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {"foo2" => "bar2", "bar2" => "foo2"}, period: 2
      myArangoTask.create
      expect(myArangoTask.retrieve.params["foo2"]).to eq "bar2"
    end
  end

  context "#destroy" do
    it "destroy" do
      myArangoTask = ArangoTask.new id: "mytaskid"
      expect(myArangoTask.destroy).to be true
    end
  end
end
