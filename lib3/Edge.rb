# === GRAPH VERTEX ===

module Arango
  class Edge < Arango::Document
    def initialize(name: nil, collection:, graph:, body: {}, rev: nil, from: nil,
      to: nil)
      assign_collection(collection)
      satisfy_class?(graph, [Arango::Graph])
      if @database.name != graph.database.name
        raise Arango::Error.new message: "Database of the collection is not the same as the one of the graph"
      end
      @graph = graph
      body["_key"] ||= name
      body["_rev"] ||= rev
      body["_from"] ||= from
      body["_to"] ||= to
      body["_id"] ||= "#{@collection.name}/#{name}" unless name.nil?
      assign_attributes(body)
      # DEFINE
      ["name", "rev", "from", "to", "key"].each do |attribute|
        define_method(:"=#{attribute}") do |attrs|
          temp_attrs = attribute
          temp_attrs = "key" if attribute == "name"
          body["_#{temp_attrs}"] = attrs
          assign_attributes(body)
        end
      end
    end

# === DEFINE ===

    attr_reader :name, :collection, :database, :server, :graph, :id, :rev,
      :body, :from, :to
    alias_method :key, :name

    def graph=(graph)
      satisfy_class?(graph, [Arango::Graph])
      @graph = graph
    end

# === TO HASH ===

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
        url: "edge/#{@collection.name}/#{@name}")
      return_element(result)
    end

# == POST ==

    def create(body: {}, waitForSync: nil)
      body = @body.merge(body)
      query = {
        "waitForSync" => waitForSync,
        "_from"       => @from.name,
        "_to"         => @to.name
      }
      result = @graph.request(action: "POST", body: body,
        query: query, url: "edge/#{@collection.name}" )
      return result if @server.async != false || silent
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, waitForSync: nil, keepNull: nil, if_match: false)
      query = {
        "waitForSync" => waitForSync,
        "keepNull"    => keepNull
      }
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @graph.request(action: "PUT",
        body: body, query: query, headers: headers,
        url: "edge/#{@collection.name}/#{@name}")
      return result if @server.async != false || silent
      body2 = result.clone
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

    def update(body: {}, waitForSync: nil, if_match: false)
      query = {"waitForSync" => waitForSync}
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @graph.request(action: "PATCH", body: body,
        query: query, headers: headers, url: "edge/#{@collection.name}/#{@name}")
      return result if @server.async != false || silent
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
        url: "edge/#{@collection.name}/#{@name}",
        query: query, headers: headers)
      return_element(result)
    end
  end
end
