# === DATABASE ===

module Arango
  class Database
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Server_Return

    def initialize(name:, server:)
      assign_server(server)
      @name = name
      @server = server
      @isSystem = nil
      @path = nil
      @id = nil
    end

# === DEFINE ===

    attr_reader :isSystem, :path, :id, :server
    attr_accessor :name

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "name"     => @name,
        "isSystem" => @isSystem,
        "path"     => @path,
        "id"       => @id
      }.delete_if{|k,v| v.nil?}
      hash["server"] = level > 0 ? @server.to_h(level-1) : @server.base_uri
      hash
    end

# === REQUEST ===

    def request(action:, url:, body: {}, headers: {},
      query: {}, key: nil, return_direct_result: false,
      skip_to_json: false, keepNull: false)
      url = "_db/#{@name}/#{url}"
      @server.request(action: action, url: url, body: body,
        headers: headers, query: query, key: key,
        return_direct_result: return_direct_result,
        skip_to_json: skip_to_json, keepNull: keepNull)
    end

# === GET ===

    def retrieve
      result = request(action: "GET", url: "_api/database/current", key: "result")
      if result.is_a?(Hash)
        @name = result["name"]
        @isSystem = result["isSystem"]
        @path = result["path"]
        @id = result["id"]
      end
      return return_directly?(result) ? result : self
    end
    alias current retrieve

# === POST ===

    def create(name: @name, users: nil)
      body = {
        "name" => name,
        "users" => users
      }
      result = @server.request(action: "POST", url: "_api/database", body: body, key: "result")
      return return_directly?(result) ? result : self
    end

# == DELETE ==

    def destroy
      @server.request(action: "DELETE", url: "_api/database/#{@name}", key: "result")
    end

# == COLLECTION ==

    def [](name)
      Arango::Collection.new(name: name, database: self)
    end

    def collection(name:, body: {}, type: "Document")
      Arango::Collection.new(name: name, database: self, body: body, type: type)
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
      result = request(action: "GET", url: "_api/gharial")
      return result if return_directly?(result)
      result["graphs"].map do |graph|
        Arango::Graph.new(database: self, name: graph["_key"], body: graph)
      end
    end

    def graph(name:, edgeDefinitions: [], orphanCollections: [],
      body: {})
      Arango::Graph.new(name: name, database: self,
        edgeDefinitions: edgeDefinitions,
        orphanCollections: orphanCollections, body: body)
    end

# == QUERY ==

    def queryProperties
      request(action: "GET", url: "_api/query/properties")
    end

    def changeQueryProperties(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil,
      trackSlowQueries: nil, maxQueryStringLength: nil, trackBindVars: nil)
      body = {
        "slowQueryThreshold" => slowQueryThreshold,
        "enabled" => enabled,
        "maxSlowQueries" => maxSlowQueries,
        "trackSlowQueries" => trackSlowQueries,
        "maxQueryStringLength" => maxQueryStringLength,
        "trackBindVars" => trackBindVars
      }
      request(action: "PUT", url: "_api/query/properties", body: body)
    end

    def currentQuery
      request(action: "GET", url: "_api/query/current")
    end

    def slowQueries
      request(action: "GET", url: "_api/query/slow")
    end

    def stopSlowQueries
      result = request(action: "DELETE", url: "_api/query/slow")
      return return_delete(result)
    end

    def clearQueryCache
      result = request(action: "DELETE", url: "_api/query-cache")
      return return_delete(result)
    end

    def propertyQueryCache
      request(action: "GET", url: "_api/query-cache/properties")
    end

    def changePropertyQueryCache(mode:, maxResults: nil)
      satisfy_category?(mode, ["off", "on", "demand"])
      body = { "mode" => mode, "maxResults" => maxResults }
      database.request(action: "PUT", url: "_api/query-cache/properties",
        body: body)
    end

# === AQL ===

  def aql(query:, count: nil, batchSize: nil, cache: nil, memoryLimit: nil,
    ttl: nil, bindVars: nil, failOnWarning: nil, profile: nil,
    maxTransactionSize: nil, skipInaccessibleCollections: nil,
    maxWarningCount: nil, intermediateCommitCount: nil,
    satelliteSyncWait: nil, fullCount: nil, intermediateCommitSize: nil,
    optimizer_rules: nil, maxPlans: nil)
    Arango::AQL.new(query: query, database: self, count: count,
      batchSize: batchSize, cache: cache, memoryLimit: memoryLimit, ttl: ttl,
      bindVars: bindVars, failOnWarning: failOnWarning, profile: profile,
      maxTransactionSize: maxTransactionSize,
      skipInaccessibleCollections: skipInaccessibleCollections,
      maxWarningCount: maxWarningCount,
      intermediateCommitCount: intermediateCommitCount,
      satelliteSyncWait: satelliteSyncWait, fullCount: fullCount,
      intermediateCommitSize: intermediateCommitSize,
      optimizer_rules: optimizer_rules, maxPlans: maxPlans)
  end

  def killAql(query:)
    satisfy_class?(query, [Arango::AQL, String])
    if query.is_a?(Arango::AQL) && query&.id.nil?
      raise Arango::Error.new message: "AQL does not have id. It could have already been killed"
    end
    id = query.is_a?(String) ? id : query.id
    request(action: "DELETE", url: "_api/query/#{id}")
  end

# === FUNCTION ===

    def aqlFunctions(namespace: nil)
      query = {"namespace" => namespace}
      request(action: "GET", url: "_api/aqlfunction",
        query: query)
    end

    def createAqlFunction(code:, name:, isDeterministic: nil)
      body = {
        "code" => code, "name" => name, "isDeterministic" => isDeterministic
      }
      request(action: "POST", url: "_api/aqlfunction", body: body)
    end

    def deleteAqlFunction(name:)
      result = request(action: "DELETE",  url: "_api/aqlfunction/#{name}")
      return return_delete(result)
    end

    # === REPLICATION ===

    def inventory(includeSystem: false)
      query = { "includeSystem": includeSystem }
      request(action: "GET", url: "api/replication/inventory",
        query: query)
    end

    def sync(endpoint:, username: nil, password:, includeSystem: nil,
      initialSyncMaxWaitTime: 0, restrictType: nil, incremental: nil,
      restrictCollections: nil, database: @name)
      satisfy_category?(restrictType, ["include", "exclude", nil])
      satisfy_category?(restrictCollections, ["include", "exclude", nil])
      satisfy_class?(password)
      body = {
        "username" => username,
        "password" => password,
        "endpoint" => endpoint,
        "database" => database,
        "restrictType"  => restrictType,
        "incremental"   => incremental,
        "includeSystem" => includeSystem,
        "restrictCollections"    =>  restrictCollections,
        "initialSyncMaxWaitTime" => initialSyncMaxWaitTime
      }
      request(action: "PUT", url: "_api/replication/sync", body: body)
    end

    def clusterInventory(includeSystem: nil)
      query = { "includeSystem": includeSystem }
      request(action: "GET", url: "_api/replication/clusterInventory", query: query)
    end

    def logger
      request(action: "GET", url: "_api/replication/logger-state")
    end

    def loggerFollow(from: nil, to: nil, chunkSize: nil, includeSystem: nil)
      query = {
        "from" => from,
        "to"   => to,
        "chunkSize"     => chunkSize,
        "includeSystem" => includeSystem
      }
      request(action: "GET", url: "_api/replication/logger-follow", query: query)
    end

    def loggerFirstTick
      request(action: "GET", url: "_api/replication/logger-first-tick", key: "firstTick")
    end

    def loggerRangeTick
      request(action: "GET", url: "_api/replication/logger-tick-ranges")
    end

    def configurationReplication
      request(action: "GET", url: "_api/replication/applier-config")
    end

    def modifyConfigurationReplication(endpoint: nil, username: nil,
      password: nil, includeSystem: nil, verbose: nil,
      connectTimeout: nil, autoResync: nil, idleMinWaitTime: nil,
      requestTimeout: nil, requireFromPresent: nil, idleMaxWaitTime: nil,
      restrictCollections: nil, restrictType: nil,
      initialSyncMaxWaitTime: nil, maxConnectRetries: nil,
      autoStart: nil, adaptivePolling: nil, connectionRetryWaitTime: nil,
      autoResyncRetries: nil, chunkSize: nil, database: @name)
      satisfy_category?(restrictType, ["include", "exclude", nil])
      body = {
        "username" => username,
        "password" => password,
        "endpoint" => endpoint,
        "database" => database,
        "verbose"    => verbose,
        "autoResync" => autoResync,
        "autoStart"  => autoStart,
        "chunkSize"  => chunkSize,
        "includeSystem"   => includeSystem,
        "connectTimeout"  => connectTimeout,
        "idleMinWaitTime" => idleMinWaitTime,
        "requestTimeout"  => requestTimeout,
        "restrictType"    => restrictType,
        "requireFromPresent" => requireFromPresent,
        "idleMaxWaitTime"    => idleMaxWaitTime,
        "maxConnectRetries"  => maxConnectRetries,
        "adaptivePolling"    => adaptivePolling,
        "initialSyncMaxWaitTime"  => initialSyncMaxWaitTime,
        "connectionRetryWaitTime" => connectionRetryWaitTime,
        "restrictCollections" =>  restrictCollections,
        "autoResyncRetries"   => autoResyncRetries
      }
      request(action: "PUT", url: "_api/replication/applier-config",
        body: body)
    end
    alias modifyReplication modifyConfigurationReplication

    def startReplication(from: nil)
      satisfy_class?(from, [String, Integer, NilClass])
      query = {from: from}
      request(action: "PUT", url: "_api/replication/applier-start",
        query: query)
    end

    def stopReplication
      request(action: "PUT", url: "_api/replication/applier-stop")
    end

    def stateReplication
      request(action: "GET", url: "_api/replication/applier-state")
    end

    def enslave(endpoint:, username: nil, password:, includeSystem: true,
      verbose: false, connectTimeout: nil, autoResync: nil,
      idleMinWaitTime: nil, requestTimeout: nil, requireFromPresent: nil,
      idleMaxWaitTime: nil, restrictCollections: nil, restrictType: nil,
      initialSyncMaxWaitTime: nil, maxConnectRetries: nil,
      adaptivePolling: nil, connectionRetryWaitTime: nil,
      autoResyncRetries: nil, chunkSize: nil, database: @name)
      satisfy_category?(restrictType, ["include", "exclude", nil])
      body = {
        "username"      => username,
        "password"      => password,
        "includeSystem" => includeSystem,
        "endpoint"      => endpoint,
        "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
        "database"        => database,
        "verbose"         => verbose,
        "connectTimeout"  => connectTimeout,
        "autoResync"      => autoResync,
        "idleMinWaitTime" => idleMinWaitTime,
        "requestTimeout"  => requestTimeout,
        "requireFromPresent" => requireFromPresent,
        "idleMaxWaitTime"    => idleMaxWaitTime,
        "restrictType"       => restrictType,
        "maxConnectRetries"  => maxConnectRetries,
        "adaptivePolling"    => adaptivePolling,
        "connectionRetryWaitTime" => connectionRetryWaitTime,
        "restrictCollections"     =>  restrictCollections,
        "autoResyncRetries" => autoResyncRetries,
        "chunkSize"         => chunkSize
      }
      request(action: "PUT", url: "_api/replication/make-slave",
        body: body)
    end

    def serverId
      request(action: "GET", url: "_api/replication/server-id", key: "serverId")
    end

# === FOXX ===

    def foxx(body: {}, mount:, development: nil, legacy: nil, provides: nil,
      name: nil, version: nil, type: "application/json", setup: nil,
      teardown: nil)
      Arango::Foxx.new(database: self, body: body, mount: mount,
        development: development, legacy: legacy, provides: provides,
        name: name, version: version, type: type, setup: setup,
        teardown: teardown)
    end

    def foxxes
      result = request(action: "GET", url: "_api/foxx")
      return result if return_directly?(result)
      result.map do |fox|
        Arango::Foxx.new(database: self, mount: fox["mount"], body: fox)
      end
    end

# === USER ACCESS ===

    def check_user(user)
      user = Arango::User.new(user: user) if user.is_a?(String)
      return user
    end
    private :check_user

    def addUserAccess(grant:, user:)
      user = check_user(user)
      user.add_database_access(grant: grant, database: @name)
    end

    def revokeUserAccess(user:)
      user = check_user(user)
      user.clear_database_access(database: @name)
    end

    def userAccess(user:)
      user = check_user(user)
      user.database_access(database: @name)
    end
  end
end
