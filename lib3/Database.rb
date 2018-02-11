# === DATABASE ===

module Arango
  class Database
    def initialize(name:, client:)
      satisfy_class?(name, "name")
      satisfy_class?(client, "client", [Arango::Client])
      @name = name
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

# == QUERY ==

    def query_properties
      Arango::AQL.properties(database: self)
    end

    def change_query_properties(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil, trackBindVars: nil)
      Arango::AQL.changeProperties(database: self, slowQueryThreshold: slowQueryThreshold, trackBindVars: trackBindVars,
        enabled: enabled, maxSlowQueries: maxSlowQueries,
        trackSlowQueries: trackSlowQueries, maxQueryStringLength: maxQueryStringLength)
    end

    def current_query
      Arango::AQL.current(database: self)
    end

    def slow_queries
      Arango::AQL.slow(database: self)
    end

    def stop_slow_queries
      Arango::AQL.stopSlow(database: self)
    end

    def clear_query_cache
      Arango::AQL.clearCache(database: self)
    end

    def property_query_cache
      Arango::AQL.propertyCache(database: self)
    end

    def change_property_query_cache(mode: nil, maxResults: nil)
      Arango::AQL.changePropertyCache(database: self, mode: mode, maxResults: maxResults)
    end

# === FUNCTION ===

    def functions(namespace: nil)
      Arango::AQL.functions(database: self, namespace: namespace)
    end

    def createFunction(code:, name:, isDeterministic: nil)
      Arango::AQL.createFunction(database: self, code: code, name: name, isDeterministic: isDeterministic)
    end

    def deleteFunction(name:)
      Arango::AQL.deleteFunction(database: self, name: name)
    end

# === ASYNC ===

    def fetchAsync(id:)
      request(action: "PUT", url: "/_api/job/#{id}")
    end

    def cancelAsync(id:)
      request(action: "PUT", url: "/_api/job/#{id}/cancel")
    end

    def destroyAsync(id: nil, stamp: nil)
      query = {"stamp" => stamp}
      request(action: "DELETE", url: "/_api/job/#{id}", "query" => query)
    end

    def destroyAsyncByType(type:, stamp: nil)
      satisfy_category?(type, ["all", "expired"], "type")
      query = {"stamp" => stamp}
      request(action: "DELETE", url: "/_api/job/#{type}", "query" => query)
    end

    def destroyAllAsync
      destroyAsyncByType(type: "all")
    end

    def destroyExpiredAsync
      destroyAsyncByType(type: "expired")
    end

    def retrieveAsync(id:)
      request(action: "GET", url: "/_api/job/#{id}")
    end

    def retrieveAsyncByType(type:, count: nil)
      satisfy_category?(type, ["done", "pending"], "type")
      query = {"count" => count}
      request(action: "GET", url: "/_api/job/#{type}", query: query)
    end

    def retrieveDoneAsync(count: nil)
      retrieveAsyncByType(type: "done", count: count)
    end

    def retrievePendingAsync(count: nil)
      retrieveAsyncByType(type: "pending", count: count)
    end

    # === REPLICATION ===

    def inventory(includeSystem: false)
      query = { "includeSystem": includeSystem }
      request(action: "GET", url: "/api/replication/inventory",
        query: query)
    end

    def createDumpBatch(ttl:, dbserver: nil)
      query = { "DBserver" => dbserver }
      body = { "ttl" => ttl }
      result = request(action: "POST", url: "_api/replication/batch",
        body: body, query: query)
      return result if return_directly?(result)
      return result["id"]
    end

    def destroyDumpBatch(id:, dbserver: nil)
      query = {"DBserver" => dbserver}
      request(action: "DELETE", url: "_api/replication/batch/#{id}",
        body: body, query: query)
    end

    def prolongDumpBatch(id:, ttl:, dbserver: nil)
      query = { "DBserver" => dbserver }
      body = { "ttl" => ttl }
      result = request(action: "PUT", url: "_api/replication/batch/#{id}",
        body: body, query: query)
      return result if return_directly?(result)
      return result["id"]
    end

    def sync(endpoint:, username:, password:, includeSystem: true,
      initialSyncMaxWaitTime: nil, restrictType: nil, incremental: nil,
      restrictCollections: nil)
      body = {
        "username" => username,
        "password" => password,
        "includeSystem" => includeSystem,
        "endpoint" => endpoint,
        "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
        "database" => @name,
        "restrictType" => restrictType,
        "incremental" => incremental,
        "restrictCollections" =>  restrictCollections
      }
      request(action: "PUT", url: "_api/replication/sync",
        body: body)
    end

    def clusterInventory(includeSystem: false)
      query = { "includeSystem": includeSystem }
      request(action: "GET", url: "_api/replication/clusterInventory",
        query: query)
    end

    def logger
      request(action: "GET", url: "_api/replication/logger-state")
    end

    def loggerFollow(from: nil, to: nil, chunkSize: nil, includeSystem: false)
      query = {
        "from": from,
        "to": to,
        "chunkSize": chunkSize,
        "includeSystem": includeSystem
      }
      request(action: "GET", url: "_api/replication/logger-follow",
        query: query)
    end

    def loggerFirstTick
      result = request(action: "GET",
        url: "_api/replication/logger-first-tick")
      return result if return_directly?(result)
      return result["firstTick"]
    end

    def loggerRangeTick
      request(action: "GET", url: "_api/replication/logger-tick-ranges")
    end

    def configurationReplication
      request(action: "GET", url: "_api/replication/applier-config")
    end

    def modifyConfigurationReplication(endpoint: nil, username: nil,
      password: nil, includeSystem: false, verbose: false,
      connectTimeout: nil, autoResync: nil, idleMinWaitTime: nil,
      requestTimeout: nil, requireFromPresent: nil, idleMaxWaitTime: nil,
      restrictCollections: nil, restrictType: nil,
      initialSyncMaxWaitTime: nil, maxConnectRetries: nil,
      autoStart: nil, adaptivePolling: nil, connectionRetryWaitTime: nil,
      autoResyncRetries: nil, chunkSize: nil)
      body = {
        "username" => username,
        "password" => password,
        "includeSystem" => includeSystem,
        "endpoint" => endpoint,
        "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
        "database" => @name,
        "verbose" => verbose,
        "connectTimeout" => connectTimeout,
        "autoResync" => autoResync,
        "idleMinWaitTime" => idleMinWaitTime,
        "requestTimeout" => requestTimeout,
        "requireFromPresent" => requireFromPresent,
        "idleMaxWaitTime" => idleMaxWaitTime,
        "restrictType" => restrictType,
        "maxConnectRetries" => maxConnectRetries,
        "autoStart" => autoStart,
        "adaptivePolling" => adaptivePolling,
        "connectionRetryWaitTime" => connectionRetryWaitTime,
        "restrictCollections" =>  restrictCollections,
        "autoResyncRetries" => autoResyncRetries,
        "chunkSize" => chunkSize
      }
      request(action: "PUT", url: "_api/replication/applier-config",
        body: body)
    end
    alias modifyReplication modifyConfigurationReplication

    def startReplication(from: nil)
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

    def enslave(endpoint:, username:, password:, includeSystem: true,
      verbose: false, connectTimeout: nil, autoResync: nil,
      idleMinWaitTime: nil, requestTimeout: nil, requireFromPresent: nil,
      idleMaxWaitTime: nil, restrictCollections: nil, restrictType: nil,
      initialSyncMaxWaitTime: nil, maxConnectRetries: nil,
      adaptivePolling: nil, connectionRetryWaitTime: nil,
      autoResyncRetries: nil, chunkSize: nil)
      body = {
        "username" => username,
        "password" => password,
        "includeSystem" => includeSystem,
        "endpoint" => endpoint,
        "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
        "database" => @name,
        "verbose" => verbose,
        "connectTimeout" => connectTimeout,
        "autoResync" => autoResync,
        "idleMinWaitTime" => idleMinWaitTime,
        "requestTimeout" => requestTimeout,
        "requireFromPresent" => requireFromPresent,
        "idleMaxWaitTime" => idleMaxWaitTime,
        "restrictType" => restrictType,
        "maxConnectRetries" => maxConnectRetries,
        "adaptivePolling" => adaptivePolling,
        "connectionRetryWaitTime" => connectionRetryWaitTime,
        "restrictCollections" =>  restrictCollections,
        "autoResyncRetries" => autoResyncRetries,
        "chunkSize" => chunkSize
      }
      request(action: "PUT", url: "_api/replication/make-slave",
        body: body)
    end

    def serverId
      result = request(action: "GET", url: "_api/replication/server-id")
      return result if return_directly?(result)
      return result["serverId"]
    end

# === FOXX ===

    def foxx
      result = request(action: "GET", url: "_api/foxx")
      return result if return_directly?(result)
      result.map do |fox|
        Arango::Foxx.new(database: self, mount: fox["mount"], body: fox)
      end
    end

# === USER ACCESS ===

    def check_user(user)
      satisfy_class?(user, "user", [Arango::User, String])
      if user.is_a?(String)
        user = Arango::User.new(user: user)
      end
      return user
    end

    def add_user_access(grant:, user:)
      user = check_user(user)
      user.add_database_access(grant: grant, database: @name)
    end

    def clear_user_access(user:)
      user = check_user(user)
      user.clear_database_access(database: @name)
    end

    def user_access(user:)
      user = check_user(user)
      user.database_access(database: @name)
    end

  # == TASKS ==
    def tasks
      result = request(action: "GET", url: "/_api/tasks")
      return result if return_directly?(result)
      result["result"].map do |task|
        Arango::Tasks.new(body: task, database: self)
      end
    end

    def task(id: nil, name: nil, type: nil, period: nil, command: nil, params: {},
      created: nil)
      Arango::Tasks.new(id: id, name: name, type: type, period: period,
        command: command, params: params, created: created, database: self)
    end
  end
end
