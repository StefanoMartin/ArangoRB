# === GRAPH VERTEX ===

module Arango
  class Vertex
    def initialize(key:, collection:, graph:, body: {}, rev: nil, from: nil, to: nil)
      satisfy_class?(key, "key")
      satisfy_class?(collection, "collection", [Arango::Collection])
      satisfy_class?(graph, "graph", [Arango::Graph])
      if collection.database.name != graph.database.name
        raise Arango::Error.new message: "Database of the collection is not the same as the one of the graph"
      end
      @collection = collection
      @graph = graph
      @database = @collection.database
      @client = @database.client
      body["_key"] ||= key
      body["_rev"] ||= rev
      body["_id"] ||= "#{@collection.name}/#{@key}"
      assign_attributes(body)
      ignore_exception(retrieve) if @client.initialize_retrieve
    end

    attr_reader :key, :collection, :database, :client, :id, :rev

    def to_h
      {
        "key" => @key,
        "id" => @id,
        "rev" => @rev,
        "collection" => @collection.name,
        "graph" => @database.name
        "body" => @body
      }.delete_if{|k,v| v.nil?}
    end

# == PRIVATE ==

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @key = result["_key"]
      @id = result["_id"]
      @rev = result["_rev"]
    end

    def return_vertex(result)
      return result if @database.client.async != false
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end

# == GET ==

    def retrieve(if_match: false)
      headers = {}
      headers["If-Match"] = @rev if if_none_match
      result = @graph.request(action: "GET", headers: headers,
        url: "vertex/#{@collection.name}/#{@key}")
      return_vertex(result)
    end

# == POST ==

    def create(body: {}, waitForSync: nil)
      body = @body.merge(body)
      query = {
        "waitForSync" => waitForSync
      }
      result = @graph.request(action: "POST", body: body,
        query: query, url: "vertex/#{@collection.name}" )
      return result if @database.client.async != false || silent
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, waitForSync: nil, keepNull: nil, if_match: false)
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

    def update(body: {}, waitForSync: nil, if_match: false)
      query = {
        "waitForSync" => waitForSync
      }
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
      query = {
        "waitForSync" => waitForSync
      }
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @graph.request(action: "DELETE",
        url: "vertex/#{@collection.name}/#{@key}",
        query: query, headers: headers)
      return_document(result)
    end
  end
end
