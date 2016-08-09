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
  end

  attr_accessor :sort, :direction, :maxDepth, :minDepth, :visitor, :itemOrder, :strategy, :filter, :init, :maxiterations, :uniqueness, :order, :expander, :vertices, :paths, :database
  attr_reader :startVertex, :graphName, :edgeCollection

  def startVertex=(startVertex) # TESTED
    if startVertex.is_a?(String)
      @startVertex = startVertex
    elsif startVertex.is_a?(ArangoDocument)
      @startVertex = startVertex.id
    else
      raise "startVertex should be a String or an ArangoDocument instance, not a #{startVertex.class}"
    end
  end

  def graphName=(graphName) # TESTED
    if graphName.is_a?(String) || graphName.nil?
      @graphName = graphName
    elsif graphName.is_a?(ArangoGraph)
      @graphName = graphName.graph
    else
      raise "graphName should be a String or an ArangoGraph instance, not a #{graphName.class}"
    end
  end

  def edgeCollection=(edgeCollection) # TESTED
    if edgeCollection.is_a?(String) || edgeCollection.nil?
      @edgeCollection = edgeCollection
    elsif edgeCollection.is_a?(ArangoCollection)
      @edgeCollection = edgeCollection.collection
    else
      raise "edgeCollection should be a String or an ArangoCollection instance, not a #{edgeCollection.class}"
    end
  end

  def in # TESTED
    @direction = "inbound"
  end

  def out # TESTED
    @direction = "outbound"
  end

  def any # TESTED
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
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/traversal", request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if result["error"]
        return @@verbose ? result : result["errorMessage"]
      else
        @vertices = result["result"]["visited"]["vertices"].map{|x| ArangoDocument.new(
          key: x["_key"],
          collection: x["_id"].split("/")[0],
          database: @database,
          body: x
        )}
        @paths = result["result"]["visited"]["paths"].map{|x|
          { "edges" => x["edges"].map{|e| ArangoDocument.new(
              key: e["_key"],
              collection: e["_id"].split("/")[0],
              database: @database,
              body: e,
              from: e["_from"],
              to: e["_to"]
            )},
              "vertices" => x["vertices"].map{|v| ArangoDocument.new(
              key: v["_key"],
              collection: v["_id"].split("/")[0],
              database: @database,
              body: v
            )}
          }
        }
        return @@verbose ? result : self
      end
    end
  end
end
