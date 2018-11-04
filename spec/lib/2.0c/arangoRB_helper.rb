require_relative './../../spec_helper'

describe Arango::Database do
  context "#retrieve" do
    it "collection" do
      expect(@myDatabase["MyCollection"].class).to be Arango::Collection
    end

    it "collection" do
      expect(@myDatabase.collection(name: "MyCollection").class).to be Arango::Collection
    end

    it "graph" do
      expect(@myDatabase.graph(name: "MyGraph").class).to be Arango::Graph
    end
  end
end

describe Arango::Collection do
  context "#retrieve" do
    it "document" do
      expect(@myCollection["MyDocument"].class).to be Arango::Document
    end

    it "database" do
      expect(@myCollection.database.class).to be Arango::Database
    end
  end
end

describe Arango::Document do
  context "#retrieve" do
    it "collection" do
      expect(@myDocument.collection.class).to be Arango::Collection
    end

    it "database" do
      expect(@myDocument.database.class).to be Arango::Database
    end
  end
end

describe Arango::Vertex do
  context "#retrieve" do
    it "collection" do
      expect(@myVertex.collection.class).to be Arango::Collection
    end

    it "database" do
      expect(@myVertex.database.class).to be Arango::Database
    end

    it "graph" do
      expect(@myVertex.graph.class).to be Arango::Graph
    end
  end
end

describe Arango::Edge do
  context "#retrieve" do
    it "collection" do
      expect(@myEdge.collection.class).to be Arango::Collection
    end

    it "database" do
      expect(@myEdge.database.class).to be Arango::Database
    end

    it "graph" do
      expect(@myEdge.graph.class).to be Arango::Graph
    end
  end
end


describe Arango::Graph do
  context "#retrieve" do
    it "database" do
      expect(@myGraph.database.class).to be Arango::Database
    end
  end
end

describe Arango::Index do
  context "#retrieve" do
    it "collection" do
      expect(@myIndex.collection.class).to be Arango::Collection
    end

    it "database" do
      expect(@myIndex.database.class).to be Arango::Database
    end
  end
end

describe Arango::Task do
  context "#retrieve" do
    it "database" do
      expect(@myTask.database.class).to be Arango::Database
    end
  end
end

describe Arango::Traversal do
  context "#retrieve" do
    it "database" do
      @myTraversal.vertex = @myDoc[0]
      @myTraversal.in
      expect(@myTraversal.database.class).to be Arango::Database
    end

    it "graph" do
      expect(@myTraversal.graph.class).to be Arango::Graph
    end

    it "vertex" do
      expect(@myTraversal.vertex.class).to be Arango::Document
    end

    it "collection" do
      expect(@myTraversal.collection.class).to be Arango::Collection
    end
  end
end

describe Arango::User do
  context "#retrieve" do
    it "database" do
      expect(@myUser["MyDatabase"].class).to be String
    end

    it "database" do
      @myUser.grant database: @myDatabase
      expect(@myUser["MyDatabase"].class).to be Arango::Database
    end

    it "database" do
      @myUser.revoke database: @myDatabase
      expect(@myUser["MyDatabase"].class).to be String
    end
  end
end
