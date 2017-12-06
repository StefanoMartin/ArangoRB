# === TRAVERSAL ===

module Arango
  class Traversal
    def initialize(body: {}, database:, edgeCollection: nil,
      sort: nil, direction: nil, minDepth: nil,
      startVertex: nil, visitor: nil, itemOrder: nil, strategy: nil,
      filter: nil, init: nil, maxIterations: nil, maxDepth: nil,
      uniqueness: nil, order: nil, graphName: nil, expander: nil,
      edgeCollection: nil) # TESTED
    satisfy_class?(database, "database", [Arango::Database])
    @sort        = body["sort"] || sort
    @direction   = body["direction"] || direction
    @maxDepth    = body["maxDepth"] || maxDepth
    @minDepth    = body["minDepth"] || minDepth
    @startVertex = body["startVertex"] || startVertex
    @visitor     = body["visitor"] || visitor
    @itemOrder   = body["itemOrder"] || itemOrder
    @strategy    = body["strategy"] || strategy
    @filter      = body["filter"] || filter
    @init        = body["init"] || init
    @maxIterations = body["maxiterations"] || maxIterations
    @uniqueness  = body["uniqueness"] || uniqueness
    @order       = body["order"] || order
    @graphName   = body["graphName"] || graphName
    @expander    = body["expander"] || expander
    @edgeCollection = body["edgeCollection"] || edgeCollection
    @database = database
    @vertices = nil
    @paths = nil
  end

  attr_accessor :sort, :direction, :maxDepth, :minDepth, :visitor, :itemOrder, :strategy, :filter, :init, :maxiterations, :uniqueness, :order, :expander
  attr_reader :idCache, :vertices, :paths, :database

  ### RETRIEVE ###

  def to_hash
    {
      "database"    => @database,
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
      "graphName"   => @graphName,
      "expander"    => @expander,
      "edgeCollection" => @edgeCollection,
      "vertices" => @vertices.map{|x| x.id},
      "paths" => @paths.map{|x| {"edges" => x["edges"].map{|e| e.id}, "vertices" => x["vertices"].map{|v| v.id} } },
      "idCache" => @idCache
    }.delete_if{|k,v| v.nil?}
  end
  alias to_h to_hash

  def startVertex
    val = @startVertex.split("/")
    collection = Arango::Collection.new(database: @database, name: val[0])
    Arango::Document.new(database: @database, collection: collection, key: val[1])
  end

  def edgeCollection
    Arango::Collection.new(name: @edgeCollection, database: @database)
  end

  def graphName
    Arango::Graph.new(key: @graphName, database: @database)
  end

  def startVertex=(startVertex) # TESTED
    satisfy_class?(startVertex, "startVertex", [String, Arango::Document])
    if startVertex.is_a?(String)
      @startVertex = startVertex
    elsif startVertex.is_a?(Arango::Document)
      @startVertex = startVertex.id
    end
  end

  def graphName=(graphName) # TESTED
    satisfy_class?(graphName, "graphName", [NilClass, String, Arango::Graph])
    if graphName.is_a?(String) || graphName.nil?
      @graphName = graphName
    elsif graphName.is_a?(Arango::Graph)
      @graphName = graphName.graph
    end
  end

  def edgeCollection=(edgeCollection) # TESTED
    satisfy_class?(edgeCollection, "edgeCollection", [NilClass, String, Arango::Collection])
    if edgeCollection.is_a?(String) || edgeCollection.nil?
      @edgeCollection = edgeCollection
    elsif edgeCollection.is_a?(ArangoCollection)
      @edgeCollection = edgeCollection.collection
    end
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
  alias graph graphName
  alias graph= graphName=

  def execute # TESTED
    body = {
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
      "graphName"   => @graphName,
      "expander"    => @expander,
      "edgeCollection" => @edgeCollection
    }
    result = @database.request(action: "POST", url: "_api/traversal", body: body)
    return result if @database.client.async != false
    @vertices = result["result"]["visited"]["vertices"].map do |x|
      collection = Arango::Collection.new(name: x["_id"].split("/")[0], database:  @database)
      Arango::Document.new(key: x["_key"], collection: collection, database: @database, body: x)
    end
    @paths = result["result"]["visited"]["paths"].map do |x|
      {
        "edges" => x["edges"].map do |e|
          collection_edge = Arango::Collection.new(name: e["_id"].split("/")[0], database:  @database, type: "Edge")
          Arango::Document.new(key: e["_key"], collection: collection_edge, database: @database, body: e, from: e["_from"], to: e["_to"] )
        end,
        "vertices" => x["vertices"].map do |v|
          collection_vertex = Arango::Collection.new(name: v["_id"].split("/")[0], database:  @database)
          Arango::Document.new(key: v["_key"], collection: collection_vertex, database: @database, body: v )
        end
      }
    end
    return return_directly?(result) ? result : self
  end
end
