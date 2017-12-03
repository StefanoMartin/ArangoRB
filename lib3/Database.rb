# === DATABASE ===

module Arango
  class Database
    def initialize(name:, client:)
      satisfy_class?(name, "name")
      satisfy_class?(client, "client", [Arango::Client])
      @client = client
      @isSystem = nil
      @path = nil
      @id = nil
      ignore_exception(retrieve) if @client.initialize_retrieve
    end

    attr_reader :name, :isSystem, :path, :id, :client

    def to_h
      {
        "name" => @name,
        "isSystem" => @isSystem,
        "path" => @path,
        "id" => @id,
        "endpoint" => "tcp://#{@client.server}:#{@client.port}"
      }.delete_if{|k,v| v.nil?}
    end

    def request(action:, url:, body: {}, headers: {}, query: {}, key: nil, return_direct_result: false, skip_to_json: false)
      url = "_db/#{@name}/#{url}"
      @client.request(action: action, url: url, body: body, headers: headers, query: query, key: key, return_direct_result: return_direct_result, skip_to_json: skip_to_json)
    end

# === GET ===

    def retrieve
      result = request(action: "GET", url: "_api/database/current")
      if result.is_a?(Hash)
        @name = result["name"]
        @isSystem = result["isSystem"]
        @path = result["path"]
        @id = result["id"]
      end
      return return_directly?(result) ? result : self
    end
    alias retrieve current
    alias retrieve info

# === POST ===

    def create(users: nil)
      satisfy_class?(users, "users", [Hash], true)
      body = {
        "name" => @name,
        "users" => users
      }
      result = @client.request(action: "POST", url: "/_api/database", body: body)
      return return_directly?(result) ? result : self
    end

# == DELETE ==

    def destroy
      @client.request(action: "DELETE", url: "/_api/database/#{@database}", @@request)
    end

# == COLLECTION ==

    def [](name)
      satisfy_class?(name, "name")
      Arango::Collection.new(name: name, database: self)
    end

    def collection(name:, body: {}, type: "Document")
      satisfy_class?(name, "name")
      Arango::Collection.new(name: name, database: self, body: body,
        type: type)
    end

    def collections(excludeSystem: true)
      query = { "excludeSystem": excludeSystem }
      result = request(action: "GET", query: query,
        url: "_api/collection")
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Collection.new(database: self,
          name: x["name"], body: x )
      end
    end

# == GRAPH ==

    def graphs
      result = request(action: "GET", url: "/_api/gharial")
      return result if return_directly?(result)
      result["graphs"].each do |graph|
        Arango::Graph.new(database: self, key: graph["_key"], body: graph)
      end
    end

    def graph(key:, edgeDefinitions: [], orphanCollections: [],
      body: {})
      Arango::Graph.new(key: key, database: database,
        edgeDefinitions: edgeDefinitions,
        orphanCollections: orphanCollections, body: body)
    end
  end
end
