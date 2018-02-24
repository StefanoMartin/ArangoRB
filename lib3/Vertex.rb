# === GRAPH VERTEX ===

module Arango
  class Vertex < Arango::Document
    include Helper_Error
    include Meta_prog
    include Helper_Return

    def initialize(name:, collection:, graph:, body: {}, rev: nil)
      satisfy_class?(collection, [Arango::Collection])
      satisfy_class?(graph, [Arango::Graph])
      if collection.database.name != graph.database.name
        raise Arango::Error.new message: "Database of the collection is not the same as the one of the graph"
      end
      @collection = collection
      @graph = graph
      @database = @collection.database
      @client = @database.client
      body["_key"] ||= name
      body["_rev"] ||= rev
      body["_id"] ||= "#{@collection.name}/#{@key}"
      assign_attributes(body)
      ignore_exception(retrieve) if @client.initialize_retrieve
    end

    attr_reader :name, :collection, :database, :client, :id, :rev
    alias key, name

    def to_h(level=0)
      hash = super(level)
      hash["graph"] = level > 0 ? @graph.to_h(level-1) : @graph.name
      hash
    end

# == PRIVATE ==

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @name = result["_key"]
      @id = result["_id"]
      @rev = result["_rev"]
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
      return result if @database.client.async != false || silent
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
      return result if @database.client.async != false || silent
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
      return result if @database.client.async != false || silent
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
      return_document(result)
    end

# === WRONG ===

    def from=(arg)
      raise Arango::Error.new message: "You cannot assign from or to to a Vertex"
    end
    alias to= from=
  end
end
