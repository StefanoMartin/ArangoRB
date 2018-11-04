require_relative './../../spec_helper'

describe "Arango::View" do
  context "#methods" do
    it "create a new instance" do
      expect(@myView.name).to eq "MyView"
    end

    it "create a new View" do
      begin
        @myView.create
      rescue Exception => e
        binding.pry
      end
      expect(@myView.name).to eq "MyView"
    end

    it "retrieve a View" do
      @myView.retrieve
      expect(@myView.name).to eq "MyView"
    end

    it "rename a View" do
      @myView.rename name: "MyView2"
      expect(@myView.name).to eq "MyView2"
    end

    it "rename a View" do
      expect(@myView.properties[:type]).to eq "arangosearch"
    end

    it "retrieve multiple views" do
      views = @myDatabase.views
      expect(views[0].class).to be Arango::View
    end

    it "destroy a View" do
      result = @myView.destroy
      expect(result).to eq true
    end
  end
end
