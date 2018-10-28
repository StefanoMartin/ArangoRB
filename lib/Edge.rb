# === GRAPH VERTEX ===

module Arango
  class Edge < Arango::Document
    def initialize(name: nil, collection:, body: {}, rev: nil, from: nil,
      to: nil)
      assign_collection(collection)
      body[:_key]  ||= name
      body[:_rev]  ||= rev
      body[:_from] ||= from
      body[:_to]   ||= to
      body[:_id]   ||= "#{@collection.name}/#{name}" unless name.nil?
      assign_attributes(body)
    end

# === DEFINE ===

    attr_reader :name, :collection, :database, :server, :graph, :from, :to

    def collection=(collection)
      satisfy_class?(collection, [Arango::Collection])
      if collection.graph.nil?
        raise Arango::Error.new err: :collection_does_not_have_a_graph, data:
          {"name_collection": collection.name, "graph": nil}
      end
      @collection = collection
      @graph      = @collection.graph
      @database   = @collection.database
      @server     = @database.server
    end
    alias assign_collection collection=

# == GET ==

    def retrieve(if_match: false)
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("GET", "edge/#{@collection.name}/#{@body[:_key]}",
        headers: headers, key: :edge)
      return_element(result)
    end

# == POST ==

    def create(body: {}, waitForSync: nil)
      body = @body.merge(body)
      query = {
        "waitForSync": waitForSync,
        "_from":      @from.id,
        "_to":        @to.id
      }
      result = @graph.request("POST", "edge/#{@collection.name}", body: body,
        query: query, key: :edge)
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, waitForSync: nil, keepNull: nil, if_match: false)
      query = {
        "waitForSync": waitForSync,
        "keepNull":    keepNull
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("PUT", "edge/#{@collection.name}/#{@body[:_key]}",
        body: body, query: query, headers: headers, key: :edge)
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

    def update(body: {}, waitForSync: nil, if_match: false)
      query = {"waitForSync": waitForSync}
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("PATCH", "edge/#{@collection.name}/#{@body[:_key]}",
        body: body, query: query, headers: headers, key: :edge)
      return result if @server.async != false
      body2 = result.clone
      body = body.merge(body2)
      body = @body.merge(body)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# === DELETE ===

    def destroy(waitForSync: nil, if_match: false)
      query = {"waitForSync": waitForSync}
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @graph.request("DELETE", "edge/#{@collection.name}/#{@body[:_key]}",
        query: query, headers: headers)
      return_delete(result)
    end
  end
end
