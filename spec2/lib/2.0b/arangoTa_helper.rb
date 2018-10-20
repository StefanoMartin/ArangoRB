require_relative './../../spec_helper'

describe Arango::Task do
  context "#new" do
    it "create new instance" do
      myArangoTask = Arango::Task.new id: "mytaskid", name: "MyTaskID",
        command: "(function(params) { require('@arangodb').print(params); })(params)",
        params: {"foo": "bar", "bar": "foo"}, period: 2, database: @myDatabase
      expect(myArangoTask.params[:foo]).to eq "bar"
    end
  end

  context "#create" do
    it "create a new Task instance" do
      myArangoTask = Arango::Task.new name: "MyTaskID",
        command: "(function(params) { require('@arangodb').print(params); })(params)",
        params: {"foo": "bar", "bar": "foo"}, period: 2, database: @myDatabase
      expect([BigDecimal, Float].include?(myArangoTask.create.created.class)).to eq true
    end

    it "create a new Task instance with ID" do
      myArangoTask = Arango::Task.new id: "mytaskid", name: "MyTaskID",
        command: "(function(params) { require('@arangodb').print(params); })(params)",
        params: {"foo2": "bar2", "bar2": "foo2"}, period: 2, database: @myDatabase
      myArangoTask.create
      expect(myArangoTask.params[:foo2]).to eq "bar2"
    end

    it "duplicate a Task instance with ID" do
      val = nil
      begin
        myArangoTask = Arango::Task.new id: "mytaskid", name: "MyTaskID",
          command: "(function(params) { require('@arangodb').print(params); })(params)",
          params: {"foo21": "bar2", "bar21": "foo21"}, period: 2, database: @myDatabase
        myArangoTask.create
      rescue Arango::Error => e
        val = e.message
      end
      expect(val).to eq "duplicate task id"
    end
  end

  context "#retrieve" do
    it "retrieve lists" do
      myArangoTask = Arango::Task.new name: "MyTaskID",
        command: "(function(params) { require('@arangodb').print(params); })(params)",
        params: {"foo2": "bar2", "bar2": "foo2"}, period: 2, database: @myDatabase
      myArangoTask.create
      result = @myDatabase.tasks
      result = result.map{|x| x.database.name}
      expect(result.include? 'MyDatabase').to be true
    end

    it "retrieve" do
      myArangoTask = Arango::Task.new name: "MyTaskID",
        command: "(function(params) { require('@arangodb').print(params); })(params)",
        params: {"foo2": "bar2", "bar2": "foo2"}, period: 2, database: @myDatabase
      myArangoTask.create
      expect(myArangoTask.retrieve.params[:foo2]).to eq "bar2"
    end
  end

  context "#destroy" do
    it "destroy" do
      myArangoTask = Arango::Task.new id: "mytaskid", database: @myDatabase
      expect(myArangoTask.destroy).to be true
    end
  end
end
