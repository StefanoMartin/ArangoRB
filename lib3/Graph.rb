# === GRAPH ===

module Arango
  class Graph
    def initialize(key:, database:, edgeDefinitions: [], orphanCollections: [], body: {})
      satisfy_class?(key, "key", [String])
      satisfy_class?(database, "database", [Arango::Database])
      satisfy_class?(edgeDefinitions, "edgeDefinitions", [Hash], true)
      satisfy_class?(orphanCollections, "orphanCollections", [Arango::Collection, String], true)

      @database = database
      @client = @database.client
      body["_key"] ||= key
      body["edgeDefinitions"] ||= edgeDefinitions
      body["orphanCollections"] ||= orphanCollections do |ed|
        ed.is_a?(Arango::Collection) ? ed.name : ed
      end
      assign_attributes(body)
    end

    attr_reader :key, :database, :client, :id, :body, :rev, :isSmart
    alias name key

    def edgeDefinitions(raw=false)
      return @edgeDefinitions if raw
      @edgeDefinitions.map do |edgedef|
        {
          "collection" => Arango::Collection.new(name: edgedef["collection"], database: @database, type: "Edge"),
          "from" => edgedef["from"].map do |from|
            Arango::Collection.new(name: from, database: @database)
          end,
          "to" => edgedef["to"].map do |to|
            Arango::Collection.new(name: to, database: @database)
          end
        }
      end
    end

    def edgeDefinitions=(edgeDefinitions)
      satisfy_class?(edgeDefinitions, "edgeDefinitions", [Hash], true)
      @edgeDefinitions = edgeDefinitions.map do |edgedef|
        name_collection = edgedef["collection"].is_a?(Arango::Collection) ? edgedef["collection"].name ? edgedef["collection"]
        {
          "collection" => name_collection,
          "from" => edgedef["from"].map do |from|
            from.is_a?(Arango::Collection) ? from.name : from
          end,
          "to" => edgedef["to"].map do |to|
            to.is_a?(Arango::Collection) ? to.name : to
          end
        }
      end
    end

    def orphanCollections(raw=false)
      return @orphanCollections if raw
      @orphanCollections.map do |oc|
        Arango::Collection.new(name: oc, database: @database)
      end
    end

    def orphanCollections=(orphanCollections)
      satisfy_class?(orphanCollections, "orphanCollections", [String, Arango::Collection], true)
      @orphanCollections = orphanCollections.map do |oc|
        oc.is_a?(Arango::Collection) ? oc.name : oc
      end
    end

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @name = result["name"]
      @edgeDefinitions = result["edgeDefinitions"]
      @orphanCollections = result["orphanCollections"]
      @id = result["_id"]
      @key = @id.split("/")[1]
      @rev = result["_rev"]
      @isSmart = result["isSmart"]
    end

    def return_graph(result)
      return result if @database.client.async != false
      assign_attributes(result["graph"])
      return return_directly?(result) ? result : self
    end

# === GET ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/gharial/#{@key}")
      return_graph(result)
    end

# === POST ===

    def create(isSmart: nil, options: nil)  # TESTED
      body = { "name" => @key, "edgeDefinitions" => @edgeDefinitions, "orphanCollections" => @orphanCollections, "isSmart" => isSmart, "options" => options }
      result = @database.request(action: "POST", url: "_api/gharial", body: body)
      return_graph(result)
    end

# === DELETE ===

    def destroy  # TESTED
      result = @database.request(action: "DELETE", url: "_api/gharial/#{@key}")
      return_graph(result)
    end

# === VERTEX COLLECTION  ===

    def vertexCollections
      result = @database.request(action: "GET", url: "_api/gharial/#{@key}/vertex")
      return result if return_directly?(result)
      result["collections"].map do |x|
        ArangoCollection.new(collection: x, database: @database)
      end
    end

    def addVertexCollection(collection:)
      satisfy_class?(collection, "collection", [String, Arango::Collection])
      collection = collection.is_a?(String) ? collection : collection.name
      body = { "collection" => collection }
      result = @database.request(action: "POST", url: "_api/gharial/#{@key}/vertex", body: body)
      return result if @database.client.async != false
      @orphanCollections |= [collection]
      return return_directly?(result) ? result : self
    end

    def removeVertexCollection(collection:, dropCollection: nil)
      query = {"dropCollection" => dropCollection}
      satisfy_class?(collection, "collection", [String, Arango::Collection])
      collection = collection.is_a?(String) ? collection : collection.name
      result = @database.request(action: "DELETE", url: "_api/gharial/#{@key}/vertex/#{collection}", query: query)
      return_graph(result)
    end

  # === EDGE COLLECTION ===

    def edgeDefinitions
      result = @database.request(action: "GET", url: "_api/gharial/#{@key}/edge")
      return result if @database.client.async != false
      @edgeDefinitions = result["collections"]
      return result if return_directly?(result)
      result["collections"].map do |x|
        ArangoCollection.new(collection: x, database: @database, type: "Edge")
      end
    end

    def addEdgeDefinition(collection:, from:, to:)
      satisfy_class?(collection, "collection", [String, Arango::Collection])
      satisfy_class?(from, "from", [String, Arango::Collection], true)
      satisfy_class?(to, "to", [String, Arango::Collection], true)
      body = {}
      body["collection"] = collection.is_a?(String) ? collection : collection.name
      body["from"] = from.map{|f| f.is_a?(String) ? f : f.name }
      body["to"] = to.map{|t| t.is_a?(String) ? t : t.name }
      result = @database.request(action: "POST", url: "_api/gharial/#{@key}/edge", body: body)
      return_graph(result)
    end

    def replaceEdgeCollection(collection:, from:, to:)
      satisfy_class?(collection, "collection", [String, Arango::Collection])
      satisfy_class?(from, "from", [String, Arango::Collection], true)
      satisfy_class?(to, "to", [String, Arango::Collection], true)
      body = {}
      body["collection"] = collection.is_a?(String) ? collection : collection.name
      body["from"] = from.map{|f| f.is_a?(String) ? f : f.name }
      body["to"] = to.map{|t| t.is_a?(String) ? t : t.name }
      result = @database.request(action: "PUT", url: "_api/gharial/#{@key}/edge", body: body)
      return_graph(result)
    end

    def removeEdgeCollection(collection:, dropCollection: nil)
      query = {"dropCollection" => dropCollection}
      collection = collection.is_a?(String) ? collection : collection.collection
      result = @database.request(action: "DELETE", url: "_api/gharial/#{@graph}/edge/#{collection}", query: query)
      return result.headers["x-arango-async-id"] if @@async == "store"
      return_graph(result)
    end
  end
end
