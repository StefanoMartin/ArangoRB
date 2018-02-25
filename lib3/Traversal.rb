# === TRAVERSAL ===

module Arango
  class Traversal
    include Helper_Error
    include Meta_prog
    include Helper_Return

    def initialize(body: {}, database:, edgeCollection: nil,
      sort: nil, direction: nil, minDepth: nil,
      startVertex: nil, visitor: nil, itemOrder: nil, strategy: nil,
      filter: nil, init: nil, maxIterations: nil, maxDepth: nil,
      uniqueness: nil, order: nil, graphName: nil, graph: nil, expander: nil,
      edgeCollection: nil)
    satisfy_class?(database, [Arango::Database])
    satisfy_category?(direction, ["outbound", "inbound", "any", nil])
    satisfy_category?(itemOrder, ["forward", "backward", nil])
    satisfy_category?(strategy, ["depthfirst", "breadthfirst", nil])
    satisfy_category?(order, ["preorder", "postorder", "preorder-expander", nil])
    @database = database
    @client = @database.client
    @sort        = body["sort"] || sort
    @direction   = body["direction"] || direction
    @maxDepth    = body["maxDepth"] || maxDepth
    @minDepth    = body["minDepth"] || minDepth
    @startVertex = return_vertex(body["startVertex"] || startVertex)
    @visitor     = body["visitor"] || visitor
    @itemOrder   = body["itemOrder"] || itemOrder
    @strategy    = body["strategy"] || strategy
    @filter      = body["filter"] || filter
    @init        = body["init"] || init
    @maxIterations = body["maxiterations"] || maxIterations
    @uniqueness  = body["uniqueness"] || uniqueness
    @order       = body["order"] || order
    @expander    = body["expander"] || expander
    @edgeCollection = return_collection(body["edgeCollection"] || edgeCollection, "Edge")
    @graph = return_graph(body["graphName"] || graph || graphName)
    @graphName = @graph&.name
    @vertices = nil
    @paths = nil
  end

  def return_vertex(vertex)
    if vertex.is_a?(Arango::Vertex) || vertex.is_a?(Arango::Document)
      return vertex
    elsif vertex.is_a?(String) && vertex.include?("/")
      val = vertex.split("/")
      collection = Arango::Collection.new(database: @database, name: val[0])
      return Arango::Document.new(collection: collection, name: val[1])
    else
      raise Arango::Error.new message: "#{vertex} should be an Arango::Vertex, an Arango::Document or a valid vertex id"
    end
  end

  def return_collection(collection, type=nil)
    if collection.is_a?(Arango::Collection) || collection.nil?
      return collection
    elsif collection.is_a?(String)
      collection_instance = Arango::Collection.new(name: edgedef["collection"],
        database: @database, type: type)
      return collection_instance
    else
      raise Arango::Error.new message: "#{collection} should be an Arango::Collection or
      a name of a class"
    end
  end

  def return_graph(graph)
    if graph.is_a?(Arango::Graph) || graph.nil?
      return graph
    elsif graph.is_a?(String)
      return Arango::Graph.new(name: graph, database: @database)
    else
      raise Arango::Error.new message: "#{graph} should be an Arango::Graph or
      a name of a graph"
    end
  end

  attr_accessor :sort, :maxDepth, :minDepth, :visitor, :filter, :init, :maxiterations,
    :uniqueness, :expander
  attr_reader :idCache, :vertices, :paths, :direction, :itemOrder,
    :strategy, :order, :database, :client, :startVertex, :edgeCollection, :graph

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

  def database=(database)
    satisfy_class?(database, [Arango::Database])
    @database = database
    @client = @database.client
  end

  def graph=(graphName)
    @graph = return_graph(graphName)
    @graphName = @graph&.name
  end

  def startVertex=(startVertex)
    @startVertex = return_vertex(startVertex)
  end

  def edgeCollection=(edgeCollection)
    return_collection(body["edgeCollection"] || edgeCollection, "Edge")
  end

  ### RETRIEVE ###

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

  def in
    @direction = "inbound"
  end

  def out
    @direction = "outbound"
  end

  def any
    @direction = "any"
  end

  alias vertex= startVertex=
  alias vertex startVertex
  alias max maxDepth
  alias max= maxDepth=
  alias min minDepth
  alias min= minDepth=
  alias collection edgeCollection
  alias collection= edgeCollection=
  alias graphName graph
  alias graphName= graph=

  def execute # TESTED
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
    return result if @database.client.async != false
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
