# === TRAVERSAL ===

module Arango
  class Traversal
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(body: {}, database:, edgeCollection: nil,
      sort: nil, direction: nil, minDepth: nil,
      startVertex: nil, visitor: nil, itemOrder: nil, strategy: nil,
      filter: nil, init: nil, maxIterations: nil, maxDepth: nil,
      uniqueness: nil, order: nil, graphName: nil, graph: nil, expander: nil,
      edgeCollection: nil)
      assign_database(database)
      satisfy_category?(direction, ["outbound", "inbound", "any", nil])
      satisfy_category?(itemOrder, ["forward", "backward", nil])
      satisfy_category?(strategy, ["depthfirst", "breadthfirst", nil])
      satisfy_category?(order, ["preorder", "postorder", "preorder-expander", nil])
      body["sort"]           ||= sort
      body["direction"]      ||= direction
      body["maxDepth"]       ||= maxDepth
      body["minDepth"]       ||= minDepth
      body["startVertex"]    ||= startVertex)
      body["visitor"]        ||= visitor
      body["itemOrder"]      ||= itemOrder
      body["strategy"]       ||= strategy
      body["filter"]         ||= filter
      body["init"]           ||= init
      body["maxiterations"]  ||= maxIterations
      body["uniqueness"]     ||= uniqueness
      body["order"]          ||= order
      body["expander"]       ||= expander
      body["edgeCollection"] ||= edgeCollection
      body["graphName"]      ||= graph || graphName
      assign_body(body)
      @vertices = nil
      @paths = nil
    end

# === DEFINE ===

    attr_accessor :sort, :maxDepth, :minDepth, :visitor, :filter, :init, :maxiterations, :uniqueness, :expander
    attr_reader :vertices, :paths, :direction, :itemOrder,
      :strategy, :order, :database, :client, :startVertex, :edgeCollection, :graph, :body

    def body=(body)
      @body = body
      @sort        = body["sort"] || @sort
      @direction   = body["direction"] || @direction
      @maxDepth    = body["maxDepth"] || @maxDepth
      @minDepth    = body["minDepth"] || @minDepth
      return_vertex(body["startVertex"] || @startVertex)
      @visitor     = body["visitor"] || @visitor
      @itemOrder   = body["itemOrder"] || @itemOrder
      @strategy    = body["strategy"] || @strategy
      @filter      = body["filter"] || @filter
      @init        = body["init"] || @init
      @maxIterations = body["maxiterations"] || @maxIterations
      @uniqueness  = body["uniqueness"] || @uniqueness
      @order       = body["order"] || @order
      @expander    = body["expander"] || @expander
      return_collection(body["edgeCollection"] || @edgeCollection, "Edge")
      return_graph(body["graphName"] || @graph || @graphName)
    end
    alias assign_body body=

    def direction=(direction)
      satisfy_category?(direction, ["outbound", "inbound", "any", nil])
      @direction = direction
    end

    def itemOrder=(itemOrder)
      satisfy_category?(itemOrder, ["forward", "backward", nil])
      @itemOrder = itemOrder
    end

    def strategy=(strategy)
      satisfy_category?(strategy, ["depthfirst", "breadthfirst", nil])
      @strategy = strategy
    end

    def order=(order)
      satisfy_category?(order, ["preorder", "postorder", "preorder-expander", nil])
      @order = order
    end

    def startVertex=(vertex)
      if vertex.is_a?(Arango::Vertex) || vertex.is_a?(Arango::Document)
        @startVertex = vertex
      elsif vertex.is_a?(String) && vertex.include?("/")
        val = vertex.split("/")
        collection = Arango::Collection.new(database: @database, name: val[0])
        @startVertex = Arango::Document.new(collection: collection, name: val[1])
      else
        raise Arango::Error.new message: "#{vertex} should be an Arango::Vertex, an Arango::Document or a valid vertex id"
      end
    end
    alias return_vertex startVertex=

    def edgeCollection=(collection)
      if collection.is_a?(Arango::Collection) && collection.type != "Edge"
        raise Arango::Error.new message: "#{collection} should be an Edge Arango::Collection or a name of a class"
      elsif (collection.is_a?(Arango::Collection) && collection.type == "Edge") || collection.nil?
        @edgeCollection = collection
      elsif collection.is_a?(String)
        collection_instance = Arango::Collection.new(name: edgedef["collection"],
          database: @database, type: "Edge")
        @edgeCollection = collection_instance
      else
        raise Arango::Error.new message: "#{collection} should be an Arango::Collection or
        a name of a class"
      end
    end
    alias return_collection edgeCollection=

    def graph=(graph)
      if graph.is_a?(Arango::Graph)
        if graph.database.name != @database.name
          raise Arango::Error.new message: "#{graph} should have the same database of the chosen database"
        end
        @graph = graph
      elsif graph.nil?
        @graph = nil
      elsif graph.is_a?(String)
        @graph = Arango::Graph.new(name: graph, database: @database)
      else
        raise Arango::Error.new message: "#{graph} should be an Arango::Graph or a name of a graph"
      end
    end
    alias return_graph graph=

    def graphName
      @graph&.name
    end

    alias vertex= startVertex=
    alias vertex startVertex
    alias max maxDepth
    alias max= maxDepth=
    alias min minDepth
    alias min= minDepth=
    alias collection edgeCollection
    alias collection= edgeCollection=
    alias graphName= graph=

    def in
      @direction = "inbound"
    end

    def out
      @direction = "outbound"
    end

    def any
      @direction = "any"
    end

# === TO HASH ===

  def to_h(level=0)
    hash = {
      "sort"        => @sort,
      "direction"   => @direction,
      "maxDepth"    => @maxDepth,
      "minDepth"    => @minDepth,
      "startVertex" => @startVertex,
      "visitor"     => @visitor,
      "itemOrder"   => @itemOrder,
      "strategy"    => @strategy,
      "filter"      => @filter,
      "init"        => @init,
      "maxiterations" => @maxiterations,
      "uniqueness"  => @uniqueness,
      "order"       => @order,
      "expander"    => @expander,
      "vertices"    => @vertices.map{|x| x.id},
      "paths"       => @paths.map do |x|
        {
          "edges"    => x["edges"].map{|e| e.id},
          "vertices" => x["vertices"].map{|v| v.id}
        }
      end,
      "idCache" => @idCache
    }
    hash["graph"] = level > 0 ? @graph&.to_h(level-1) : @graph&.name
    hash["edgeCollection"] = level > 0 ? @edgeCollection&.to_h(level-1) : @edgeCollection&.name
    hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name
    hash.delete_if{|k,v| v.nil?}
    hash
  end

# === EXECUTE ===

  def execute
    body = {
      "sort"        => @sort,
      "direction"   => @direction,
      "maxDepth"    => @maxDepth,
      "minDepth"    => @minDepth,
      "startVertex" => @startVertex&.name,
      "visitor"     => @visitor,
      "itemOrder"   => @itemOrder,
      "strategy"    => @strategy,
      "filter"      => @filter,
      "init"        => @init,
      "maxiterations" => @maxiterations,
      "uniqueness"  => @uniqueness,
      "order"       => @order,
      "graphName"   => @graph&.name,
      "expander"    => @expander,
      "edgeCollection" => @edgeCollection&.name
    }
    result = @database.request(action: "POST", url: "_api/traversal", body: body)
    return result if @client.async != false
    @vertices = result["result"]["visited"]["vertices"].map do |x|
      collection = Arango::Collection.new(name: x["_id"].split("/")[0], database:  @database)
      Arango::Document.new(name: x["_key"], collection: collection, body: x)
    end
    @paths = result["result"]["visited"]["paths"].map do |x|
      {
        "edges" => x["edges"].map do |e|
          collection_edge = Arango::Collection.new(name: e["_id"].split("/")[0], database:  @database, type: "Edge")
          Arango::Document.new(name: e["_key"], collection: collection_edge, body: e, from: e["_from"], to: e["_to"] )
        end,
        "vertices" => x["vertices"].map do |v|
          collection_vertex = Arango::Collection.new(name: v["_id"].split("/")[0], database:  @database)
          Arango::Document.new(name: v["_key"], collection: collection_vertex, body: v )
        end
      }
    end
    return return_directly?(result) ? result : self
  end
end
