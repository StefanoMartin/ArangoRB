# === DATABASE ===

module Arango
  class Database
    def initialize(database:, client:)
      satisfy_class?(database, "database", [Arango::Database, String])
      satisfy_class?(client, "client", [Arango::Client])
      @database = database.is_a?(Arango::Database) ? database.database : database
      @client = client
      @isSystem = nil
      @path = nil
      @id = nil
    end

    attr_reader :database, :isSystem, :path, :id, :client
    alias name database

    def to_hash
      {
        "database" => @database,
        "isSystem" => @isSystem,
        "path" => @path,
        "id" => @id,
        "endpoint" => "tcp://#{@client.server}:#{@client.port}"
      }.delete_if{|k,v| v.nil?}
    end
    alias to_h to_hash

    def [](collection_name)
      satisfy_class?(collection_name, "collection_name")
      ArangoCollection.new(collection: collection_name, database: self,
        client: @client)
    end
    alias collection []

    def graph(graph_name)
      ArangoGraph.new(graph: graph_name, database: self, client: @client)
    end

# === GET ===

    def info
      @client.request(action: "GET", url: "/_db/#{@database}/_api/database/current")
    end

    def retrieve  # TESTED
      result = @client.request(action: "GET", url: "/_db/#{@database}/_api/database/current")
      return result if @client.async != false
      @isSystem = result["isSystem"]
      @path = result["path"]
      @id = result["id"]
      return self
    end

# === POST ===

    def create(username: nil, passwd: nil, users: nil)  # TESTED
      body = {
        "name" => @database,
        "username" => username,
        "passwd" => passwd,
        "users" => users
      }
      result = @client.request(action: "POST", url: "/_api/database",
        body: body)
      return result if @client.async != false
      return self
    end

# === LISTS ===

    def collections(excludeSystem: true)
      query = { "excludeSystem": excludeSystem }
      result = @client.request(action: "GET", url: "/_db/#{@database}/_api/collection", query: query)
      return result if @client.async != false
      result["result"].map do |x|
        type = x['type'] == 3 ? 'Edge' : 'Collection'
        ArangoCollection.new(database: self, collection: x["name"], type: type, client: @client )
      end
    end

    def graphs
      result = @client.request(action: "GET", url: "/_db/#{@database}/_api/gharial")
      return result if @client.async != false
      result["graphs"].map do |x|
        ArangoGraph.new(database: self, graph: x["_key"],
          edgeDefinitions: x["edgeDefinitions"], orphanCollections: x["orphanCollections"], client: @client)
      end
    end

    def functions
      @client.request(action: "GET", url: "/_db/#{@database}/_api/aqlfunction")
    end

    # === QUERY ===

    def aql(query:, batchSize: nil, ttl: nil, cache: nil, options: nil, bindVars: nil)
      Arango::AQL.new(query: query, database: @database, client: @client, batchSize: batchSize, ttl: ttl, cache: cache, options: options, bindVars: bindVars)
    end

    def propertiesQuery
      @client.request(action: "GET", url: "/_db/#{@database}/_api/query/properties")
    end

    def currentQuery
      @client.request(action: "GET", url: "/_db/#{@database}/_api/query/current")
    end

    def slowQuery
      @client.request(action: "GET", url: "/_db/#{@database}/_api/query/slow")
    end

    def stopSlowQuery
      @client.request(action: "DELETE", url: "/_db/#{@database}/_api/query/slow")
    end

    def killQuery(query:)
      id = query.is_a?(Arango::AQL) ? query.id : query.is_a?(String) ? query : nil
      @client.request(action: "DELETE", url: "/_db/#{@database}/_api/query/#{id}")
    end

    def changePropertiesQuery(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil)
      body = {
        "slowQueryThreshold" => slowQueryThreshold,
        "enabled" => enabled,
        "maxSlowQueries" => maxSlowQueries,
        "trackSlowQueries" => trackSlowQueries,
        "maxQueryStringLength" => maxQueryStringLength
      }
      @client.request(action: "PUT", url: "/_db/#{@database}/_api/query/properties", body: body)
    end

# === CACHE ===

    def clearCache
      @client.request(action: "DELETE", url: "/_db/#{@database}/_api/query-cache")
    end

    def propertyCache  # TESTED
      @client.request(action: "GET", url: "/_db/#{@database}/_api/query-cache/properties")
    end

    def changePropertyCache(mode: nil, maxResults: nil)
      body = { "mode" => mode, "maxResults" => maxResults }
      @client.request(action: "PUT", url: "/_db/#{@database}/_api/query-cache/properties", body: body}
    end

# === AQL FUNCTION ===

    def createFunction(code:, name:, isDeterministic: nil)
      body = {
        "code" => code,
        "name" => name,
        "isDeterministic" => isDeterministic
      }
      @client.request(action: "POST", url: "/_db/#{@database}/_api/aqlfunction", body: body)
    end

    def deleteFunction(name:)
      @client.request(action: "DELETE", url: "/_db/#{@database}/_api/aqlfunction/#{name}")
    end

    # === REPLICATION ===

    def inventory(includeSystem: false)
      query = { "includeSystem": includeSystem }
      @client.request(action: "GET", url: "/_db/#{@database}/_api/replication/inventory", query: query)
    end

    def clusterInventory(includeSystem: false)
      query = { "includeSystem": includeSystem }
      @client.request(action: "GET", url: "/_db/#{@database}/_api/replication/clusterInventory", query: query)
    end

    # === USER ===

    def grant(user:) # TESTED
      user = user.user if user.is_a?(Arango::User)
      body = { "grant" => "rw" }
      @client.request(action: "PUT", url: "/_api/user/#{user}/database/#{@database}", body: body, caseTrue: true)
    end

    def revoke(user: @@user) # TESTED
      user = user.user if user.is_a?(Arango::User)
      body = { "grant" => "none" }
      @client.request(action: "PUT", url: "/_api/user/#{user}/database/#{@database}", body: body, caseTrue: true)
    end
  end
