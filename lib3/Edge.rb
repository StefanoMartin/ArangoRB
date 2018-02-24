# === GRAPH VERTEX ===

module Arango
  class Edge < Arango::Document
    include Helper_Error
    include Meta_prog
    include Helper_Return

    def initialize(name:, collection:, graph:, body: {}, rev: nil, from: nil, to: nil)
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
      body["_from"] ||= from
      body["_to"] ||= to
      body["_id"] ||= "#{@collection.name}/#{name}"
      assign_attributes(body)
      ["name", "rev", "from", "to", "key"].each do |attribute|
        define_method(:"=#{attribute}") do |attrs|
          temp_attrs = attribute
          temp_attrs = "key" if attribute == "name"
          body["_#{temp_attrs}"] = attrs
          assign_attributes(body)
        end
      end
    end

    attr_reader :name, :collection, :database, :client, :graph, :id, :rev, :body, :from, :to
    alias_method :key, :name

    def collection=(collection)
      satisfy_class?(collection, [Arango::Collection])
      @collection = collection
      @database = @collection.database
      @client = @database.client
    end

    def graph=(graph)
      satisfy_class?(graph, [Arango::Graph])
      @graph = graph
    end

    def to_h(level=0)
      hash = {
        "name" => @name,
        "id" => @id,
        "rev" => @rev,
        "body" => @body
      }
      hash["collection"] = level > 0 ? @collection.to_h(level-1) : @collection.name
      hash["graph"] = level > 0 ? @graph.to_h(level-1) : @graph.name
      hash["from"] = level > 0 ? @from.to_h(level-1) : @from&.name
      hash["to"] = level > 0 ? @to.to_h(level-1) : @to&.name
      hash.delete_if{|k,v| v.nil?}
      hash
    end

# == GET ==

    def retrieve(if_match: false)
      headers = {}
      headers["If-Match"] = @rev if if_none_match
      result = @graph.request(action: "GET", headers: headers,
        url: "_api/edge/#{@collection.name}/#{@key}")
      return_element(result)
    end

# == POST ==

    def create(body: {}, waitForSync: nil)
      body = @body.merge(body)
      query = {
        "waitForSync" => waitForSync,
        "_from" => @from,
        "_to" => @to
      }
      result = @graph.request(action: "POST", body: body,
        query: query, url: "_api/edge/#{@collection.name}" )
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
        url: "_api/vertex/#{@collection.name}/#{@key}")
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
        query: query, headers: headers, url: "_api/vertex/#{@collection.name}/#{@key}")
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
