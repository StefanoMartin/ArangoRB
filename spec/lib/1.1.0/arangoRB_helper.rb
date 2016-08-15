require_relative './../../spec_helper'

describe ArangoDatabase do
  context "#retrieve" do
    it "collection" do
      expect(@myDatabase["MyCollection"].class).to be ArangoCollection
    end

    it "collection" do
      expect(@myDatabase.collection("MyCollection").class).to be ArangoCollection
    end

    it "graph" do
      expect(@myDatabase.graph("MyGraph").class).to be ArangoGraph
    end
  end
end

describe ArangoCollection do
  context "#retrieve" do
    it "document" do
      expect(@myCollection["MyDocument"].class).to be ArangoDocument
    end

    it "database" do
      expect(@myCollection.database.class).to be ArangoDatabase
    end
  end
end

describe ArangoDocument do
  context "#retrieve" do
    it "collection" do
      expect(@myDocument.collection.class).to be ArangoCollection
    end

    it "database" do
      expect(@myDocument.database.class).to be ArangoDatabase
    end
  end
end

describe ArangoVertex do
  context "#retrieve" do
    it "collection" do
      expect(@myVertex.collection.class).to be ArangoCollection
    end

    it "database" do
      expect(@myVertex.database.class).to be ArangoDatabase
    end

    it "graph" do
      expect(@myVertex.graph.class).to be ArangoGraph
    end
  end
end

describe ArangoEdge do
  context "#retrieve" do
    it "collection" do
      expect(@myEdge.collection.class).to be ArangoCollection
    end

    it "database" do
      expect(@myEdge.database.class).to be ArangoDatabase
    end

    it "graph" do
      expect(@myEdge.graph.class).to be ArangoGraph
    end
  end
end


describe ArangoGraph do
  context "#retrieve" do
    it "database" do
      expect(@myGraph.database.class).to be ArangoDatabase
    end
  end
end

describe ArangoIndex do
  context "#retrieve" do
    it "collection" do
      expect(@myIndex.collection.class).to be ArangoCollection
    end

    it "database" do
      expect(@myIndex.database.class).to be ArangoDatabase
    end
  end
end

describe ArangoTask do
  context "#retrieve" do
    it "database" do
      expect(@myTask.database.class).to be ArangoDatabase
    end
  end
end

describe ArangoTraversal do
  context "#retrieve" do
    it "database" do
      @myTraversal.vertex = @myDoc[0]
  		@myTraversal.graph = @myGraph
  		@myTraversal.collection = @myEdgeCollection
      @myTraversal.in
      expect(@myTraversal.database.class).to be ArangoDatabase
    end

    it "graph" do
      expect(@myTraversal.graph.class).to be ArangoGraph
    end

    it "vertex" do
      expect(@myTraversal.vertex.class).to be ArangoDocument
    end

    it "collection" do
      expect(@myTraversal.collection.class).to be ArangoCollection
    end
  end
end

describe ArangoUser do
  context "#retrieve" do
    it "database" do
      expect(@myUser["MyDatabase"].class).to be String
    end

    it "database" do
      @myUser.grant database: @myDatabase
      expect(@myUser["MyDatabase"].class).to be ArangoDatabase
    end

    it "database" do
      @myUser.revoke database: @myDatabase
      expect(@myUser["MyDatabase"].class).to be String
    end
  end
end
