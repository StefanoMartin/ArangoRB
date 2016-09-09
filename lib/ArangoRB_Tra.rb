# === TRAVERSAL ===

class ArangoTraversal < ArangoServer
  def initialize(body: {}, database: @@database, graph: nil, edgeCollection: nil) # TESTED
    @sort        = body["sort"]
    @direction   = body["direction"]
    @maxDepth    = body["maxDepth"]
    @minDepth    = body["minDepth"]
    @startVertex = body["startVertex"]
    @visitor     = body["visitor"]
    @itemOrder   = body["itemOrder"]
    @strategy    = body["strategy"]
    @filter      = body["filter"]
    @init        = body["init"]
    @maxiterations = body["maxiterations"]
    @uniqueness  = body["uniqueness"]
    @order       = body["order"]
    @graphName   = body["graphName"].nil? ? graph : body["graphName"]
    @expander    = body["expander"]
    @edgeCollection = body["edgeCollection"].nil? ? edgeCollection : body["edgeCollection"]
    @database = database
    @vertices = nil
    @paths = nil
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
  end

  attr_accessor :sort, :direction, :maxDepth, :minDepth, :visitor, :itemOrder, :strategy, :filter, :init, :maxiterations, :uniqueness, :order, :expander
  attr_reader :idCache, :vertices, :paths

  ### RETRIEVE ###

  def startVertex
    val = @startVertex.split("/")
    ArangoDocument.new(database: @database, collection: val[0], key: val[1])
  end

  def edgeCollection
    ArangoCollection.new(collection: @edgeCollection, database: @database)
  end

  def database
    ArangoDatabase.new(database: @database)
  end

  def graphName
    ArangoGraph.new(graph: @graphName, database: @database).retrieve
  end

  def startVertex=(startVertex) # TESTED
    if startVertex.is_a?(String)
      @startVertex = startVertex
    elsif startVertex.is_a?(ArangoDocument)
      @startVertex = startVertex.id
    else
      raise "startVertex should be a String or an ArangoDocument instance, not a #{startVertex.class}"
    end
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
  end

  def graphName=(graphName) # TESTED
    if graphName.is_a?(String) || graphName.nil?
      @graphName = graphName
    elsif graphName.is_a?(ArangoGraph)
      @graphName = graphName.graph
    else
      raise "graphName should be a String or an ArangoGraph instance, not a #{graphName.class}"
    end
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
  end

  def edgeCollection=(edgeCollection) # TESTED
    if edgeCollection.is_a?(String) || edgeCollection.nil?
      @edgeCollection = edgeCollection
    elsif edgeCollection.is_a?(ArangoCollection)
      @edgeCollection = edgeCollection.collection
    else
      raise "edgeCollection should be a String or an ArangoCollection instance, not a #{edgeCollection.class}"
    end
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
  end

  def in # TESTED
    @direction = "inbound"
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
  end

  def out # TESTED
    @direction = "outbound"
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
  end

  def any # TESTED
    @direction = "any"
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
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
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/traversal", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    return @@verbose ? result : result["errorMessage"] if result["error"]
    @vertices = result["result"]["visited"]["vertices"].map{|x| ArangoDocument.new(key: x["_key"], collection: x["_id"].split("/")[0], database: @database, body: x)}
    @paths = result["result"]["visited"]["paths"].map{|x|
      {
        "edges" => x["edges"].map{|e| ArangoDocument.new(key: e["_key"], collection: e["_id"].split("/")[0], database: @database, body: e, from: e["_from"], to: e["_to"] )},
        "vertices" => x["vertices"].map{|v| ArangoDocument.new(key: v["_key"], collection: v["_id"].split("/")[0], database: @database, body: v )}
      }
    }
    @idCache = "ATR_#{@database}_#{@direction}_#{@startVertex}_" + (@graphName.nil? ? "#{@edgeCollection}" : "#{@graphName}")
    @@verbose ? result : self
  end
end
