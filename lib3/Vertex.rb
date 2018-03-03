# === GRAPH VERTEX ===

module Arango
  class Vertex < Arango::Document
    def initialize(name: nil, collection:, graph:, body: {}, rev: nil)
      assign_collection(collection)
      satisfy_class?(graph, [Arango::Graph])
      if @database.name != graph.database.name
        raise Arango::Error.new message: "Database of the collection is not the same as the one of the graph"
      end
      @graph = graph
      body["_key"] ||= name
      body["_rev"] ||= rev
      body["_id"]  ||= "#{@collection.name}/#{name}" unless name.nil?
      assign_attributes(body)
      # DEFINE
      ["name", "rev", "key"].each do |attribute|
        define_singleton_method(:"=#{attribute}") do |attrs|
          temp_attrs = attribute
          temp_attrs = "key" if attribute == "name"
          body["_#{temp_attrs}"] = attrs
          assign_attributes(body)
        end
      end
    end

# === DEFINE ===

    attr_reader :name, :collection, :database, :server, :id, :rev
    alias key name

    def to_h(level=0)
      hash = super(level)
      hash["graph"] = level > 0 ? @graph.to_h(level-1) : @graph.name
      hash
    end

# == GET ==

    def retrieve(if_match: false)
      headers = {}
      headers["If-Match"] = @rev if if_none_match
      result = @graph.request(action: "GET", headers: headers,
        url: "vertex/#{@collection.name}/#{@name}")
      return_element(result)
    end

# == POST ==

    def create(body: {}, waitForSync: nil)
      body = @body.merge(body)
      query = {"waitForSync" => waitForSync}
      result = @graph.request(action: "POST", body: body,
        query: query, url: "vertex/#{@collection.name}" )
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, waitForSync: nil, if_match: false)
      query = {
        "waitForSync" => waitForSync,
        "keepNull" => keepNull
      }
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @graph.request(action: "PUT",
        body: body, query: query, headers: headers,
        url: "vertex/#{@collection.name}/#{@key}")
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

    def update(body: {}, waitForSync: nil, if_match: false, keepNull: nil)
      query = {"waitForSync" => waitForSync, "keepNull" => keepNull}
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @graph.request(action: "PATCH", body: body,
        query: query, headers: headers, url: "vertex/#{@collection.name}/#{@key}")
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      body = @body.merge(body)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# === DELETE ===

    def destroy(waitForSync: nil, if_match: false)
      query = {"waitForSync" => waitForSync}
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @graph.request(action: "DELETE",
        url: "vertex/#{@collection.name}/#{@key}",
        query: query, headers: headers)
      return_element(result)
    end

# === TRAVERSAL ===

    def traversal(body: {}, sort: nil, direction: nil, minDepth: nil,
      visitor: nil, itemOrder: nil, strategy: nil,
      filter: nil, init: nil, maxIterations: nil, maxDepth: nil,
      uniqueness: nil, order: nil, expander: nil,
      edgeCollection: nil)
      Arango::Traversal.new(body: body, database: @database,
        sort: sort, direction: direction, minDepth: minDepth,
        startVertex: self, visitor: visitor,itemOrder: itemOrder,
        strategy: strategy, filter: filter, init: init,
        maxIterations: maxIterations, maxDepth: maxDepth,
        uniqueness: uniqueness, order: order, graph: @graph,
        expander: expander, edgeCollection: edgeCollection)
    end

# === WRONG ===

    def from=(arg)
      raise Arango::Error.new message: "You cannot assign from or to to a Vertex"
    end
    alias to= from=
  end
end
