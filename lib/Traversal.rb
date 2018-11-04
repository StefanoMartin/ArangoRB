# === TRAVERSAL ===

module Arango
  class Traversal
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(body: {}, edgeCollection: nil,
      sort: nil, direction: nil, minDepth: nil,
      vertex:, visitor: nil, itemOrder: nil, strategy: nil,
      filter: nil, init: nil, maxIterations: nil, maxDepth: nil,
      uniqueness: nil, order: nil, expander: nil)
      assign_database(database)
      satisfy_category?(direction, ["outbound", "inbound", "any", nil])
      satisfy_category?(itemOrder, ["forward", "backward", nil])
      satisfy_category?(strategy, ["depthfirst", "breadthfirst", nil])
      satisfy_category?(order, ["preorder", "postorder", "preorder-expander", nil])
      body[:sort]           ||= sort
      body[:direction]      ||= direction
      body[:maxDepth]       ||= maxDepth
      body[:minDepth]       ||= minDepth
      body[:startVertex]    ||= vertex
      body[:visitor]        ||= visitor
      body[:itemOrder]      ||= itemOrder
      body[:strategy]       ||= strategy
      body[:filter]         ||= filter
      body[:init]           ||= init
      body[:maxiterations]  ||= maxIterations
      body[:uniqueness]     ||= uniqueness
      body[:order]          ||= order
      body[:expander]       ||= expander
      body[:edgeCollection] ||= edgeCollection
      assign_body(body)
      @vertices = nil
      @paths = nil
    end

# === DEFINE ===

    attr_accessor :sort, :maxDepth, :minDepth, :visitor, :filter, :init, :maxiterations, :uniqueness, :expander
    attr_reader :vertices, :paths, :direction, :itemOrder,
      :strategy, :order, :database, :server, :vertex, :edgeCollection, :graph, :body
    alias startVertex vertex

    def body=(body)
      @body = body
      @sort        = body[:sort] || @sort
      @direction   = body[:direction] || @direction
      @maxDepth    = body[:maxDepth] || @maxDepth
      @minDepth    = body[:minDepth] || @minDepth
      return_vertex(body[:startVertex] || @vertex)
      @visitor     = body[:visitor] || @visitor
      @itemOrder   = body[:itemOrder] || @itemOrder
      @strategy    = body[:strategy] || @strategy
      @filter      = body[:filter] || @filter
      @init        = body[:init] || @init
      @maxIterations = body[:maxiterations] || @maxIterations
      @uniqueness  = body[:uniqueness] || @uniqueness
      @order       = body[:order] || @order
      @expander    = body[:expander] || @expander
      return_edgeCollection(body[:edgeCollection] || @edgeCollection)
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
      case vertex
      when Arango::Edge
      when Arango::Document, Arango::Vertex
        @vertex = vertex
        @collection = @vertex.collection
        @database = @collection.database
        @graph  = @collection.graph
        @server = @database.server
        return
      when String
        if @database.nil?
          raise Arango::Error.new err: :database_undefined_for_traversal
        end
        if vertex.include?("/")
          val = vertex.split("/")
          @collection = Arango::Collection.new(database: @database, name: val[0])
          @vertex = Arango::Document.new(collection: collection, name: val[1])
          return
        end
      end
      raise Arango::Error.new err: :wrong_start_vertex_type
    end
    alias vertex= startVertex=
    alias return_vertex startVertex=

    def edgeCollection=(collection)
      satisfy_class?(collection, [Arango::Collection, String])
      case collection
      when Arango::Collection
        if collection.type != :edge
          raise Arango::Error.new err: :edge_collection_should_be_of_type_edge
        end
        @edgeCollection = collection
      when String
        collection_instance = Arango::Collection.new(name: edgedef[:collection],
          database: @database, type: :edge, graph: @graph)
        @edgeCollection = collection_instance
      end
    end
    alias return_edgeCollection edgeCollection=

    alias vertex= startVertex=
    alias vertex startVertex
    alias max maxDepth
    alias max= maxDepth=
    alias min minDepth
    alias min= minDepth=
    alias collection edgeCollection
    alias collection= edgeCollection=

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

    def to_h
      {
        "sort": @sort,
        "direction": @direction,
        "maxDepth": @maxDepth,
        "minDepth": @minDepth,
        "visitor": @visitor,
        "itemOrder": @itemOrder,
        "strategy": @strategy,
        "filter": @filter,
        "init": @init,
        "maxiterations": @maxiterations,
        "uniqueness": @uniqueness,
        "order": @order,
        "expander": @expander,
        "vertices": @vertices.map{|x| x.id},
        "paths": @paths.map do |x|
          {
            "edges": x[:edges].map{|e| e.id},
            "vertices": x[:vertices].map{|v| v.id}
          }
        end,
        "idCache": @idCache,
        "startVertex": @vertex&.id,
        "graph": @graph&.name,
        "edgeCollection": @edgeCollection&.name,
        "database": @database.name
      }.delete_if{|k,v| v.nil?}
    end

  # === EXECUTE ===

    def execute
      body = {
        "sort": @sort,
        "direction": @direction,
        "maxDepth": @maxDepth,
        "minDepth": @minDepth,
        "startVertex": @vertex&.id,
        "visitor": @visitor,
        "itemOrder": @itemOrder,
        "strategy": @strategy,
        "filter": @filter,
        "init": @init,
        "maxiterations": @maxiterations,
        "uniqueness": @uniqueness,
        "order": @order,
        "graphName": @graph&.name,
        "expander": @expander,
        "edgeCollection": @edgeCollection&.name
      }
      result = @database.request("POST", "_api/traversal", body: body)
      return result if @server.async != false
      @vertices = result[:result][:visited][:vertices].map do |x|
        collection = Arango::Collection.new(name: x[:_id].split("/")[0],
          database:  @database)
        Arango::Document.new(name: x[:_key], collection: collection, body: x)
      end
      @paths = result[:result][:visited][:paths].map do |x|
        {
          "edges": x[:edges].map do |e|
            collection_edge = Arango::Collection.new(name: e[:_id].split("/")[0],
              database:  @database, type: :edge)
            Arango::Document.new(name: e[:_key], collection: collection_edge,
              body: e, from: e[:_from], to: e[:_to])
          end,
          "vertices": x[:vertices].map do |v|
            collection_vertex = Arango::Collection.new(name: v[:_id].split("/")[0],
              database:  @database)
            Arango::Document.new(name: v[:_key], collection: collection_vertex, body: v)
          end
        }
      end
      return return_directly?(result) ? result : self
    end
  end
end
