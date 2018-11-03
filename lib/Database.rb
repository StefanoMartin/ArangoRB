# === DATABASE ===

module Arango
  class Database
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Server_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      server = hash[:server]
      if server.is_a?(Arango::Server) && server.active_cache
        cache_name = hash[:name]
        cached = server.cache.cache.dig(:database, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          return cached
        end
      end
      super
    end

    def initialize(name:, server:, cache_name: nil)
      assign_server(server)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:database, cache_name, self)
      end
      @name = name
      @server = server
      @isSystem = nil
      @path = nil
      @id = nil
    end

# === DEFINE ===

    attr_reader :isSystem, :path, :id, :server, :cache_name
    attr_accessor :name

# === TO HASH ===

    def to_h
      {
        "name":     @name,
        "isSystem": @isSystem,
        "path":     @path,
        "id":       @id,
        "cache_name": @cache_name,
        "server": @server.base_uri
      }.delete_if{|k,v| v.nil?}
    end

# === REQUEST ===

    def request(action, url, body: {}, headers: {},
      query: {}, key: nil, return_direct_result: false,
      skip_to_json: false, keepNull: false)
      url = "_db/#{@name}/#{url}"
      @server.request(action, url, body: body,
        headers: headers, query: query, key: key,
        return_direct_result: return_direct_result,
        skip_to_json: skip_to_json, keepNull: keepNull)
    end

# === GET ===

    def assign_attributes(result)
      return unless result.is_a?(Hash)
      @name     = result[:name]
      @isSystem = result[:isSystem]
      @path     = result[:path]
      @id       = result[:id]
      if @server.active_cache && @cache_name.nil?
        @cache_name = result[:name]
        @server.cache.save(:database, @cache_name, self)
      end
    end

    def retrieve
      result = request("GET", "_api/database/current", key: :result)
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end
    alias current retrieve

# === POST ===

    def create(name: @name, users: nil)
      body = {
        "name":  name,
        "users": users
      }
      result = @server.request("POST", "_api/database", body: body, key: :result)
      return return_directly?(result) ? result : self
    end

# == DELETE ==

    def destroy
      @server.request("DELETE", "_api/database/#{@name}", key: :result)
    end

# == COLLECTION ==

    def [](name)
      Arango::Collection.new(name: name, database: self)
    end

    def collection(name:, body: {}, type: :document)
      Arango::Collection.new(name: name, database: self, body: body, type: type)
    end

    def collections(excludeSystem: true)
      query = { "excludeSystem": excludeSystem }
      result = request("GET", "_api/collection", query: query)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Collection.new(database: self, name: x[:name], body: x )
      end
    end

# == GRAPH ==

    def graphs
      result = request("GET", "_api/gharial")
      return result if return_directly?(result)
      result[:graphs].map do |graph|
        Arango::Graph.new(database: self, name: graph[:_key], body: graph)
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
      request("GET", "_api/query/properties")
    end

    def changeQueryProperties(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil,
      trackSlowQueries: nil, maxQueryStringLength: nil, trackBindVars: nil)
      body = {
        "slowQueryThreshold":   slowQueryThreshold,
        "enabled":              enabled,
        "maxSlowQueries":       maxSlowQueries,
        "trackSlowQueries":     trackSlowQueries,
        "maxQueryStringLength": maxQueryStringLength,
        "trackBindVars":        trackBindVars
      }
      request("PUT", "_api/query/properties", body: body)
    end

    def currentQuery
      request("GET", "_api/query/current")
    end

    def slowQueries
      request("GET", "_api/query/slow")
    end

    def stopSlowQueries
      result = request("DELETE", "_api/query/slow")
      return return_delete(result)
    end

# === QUERY CACHE ===

    def clearQueryCache
      result = request("DELETE", "_api/query-cache")
      return return_delete(result)
    end

    def retrieveQueryCache
      request("GET", "_api/query-cache/entries")
    end

    def propertyQueryCache
      request("GET", "_api/query-cache/properties")
    end

    def changePropertyQueryCache(mode:, maxResults: nil)
      satisfy_category?(mode, ["off", "on", "demand"])
      body = { "mode": mode, "maxResults": maxResults }
      database.request("PUT", "_api/query-cache/properties", body: body)
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

# === AQL FUNCTION ===

    def aqlFunctions(namespace: nil)
      request("GET", "_api/aqlfunction", query: {"namespace": namespace}, key: :result)
    end

    def createAqlFunction(code:, name:, isDeterministic: nil)
      body = { "code": code, "name": name, "isDeterministic": isDeterministic }
      request("POST", "_api/aqlfunction", body: body)
    end

    def deleteAqlFunction(name:)
      result = request("DELETE", "_api/aqlfunction/#{name}")
      return return_delete(result)
    end

    # === REPLICATION ===

    def inventory(includeSystem: nil, global: nil, batchId:)
      query = {
        "includeSystem": includeSystem,
        "global": global,
        "batchId": batchId
      }
      request("GET", "_api/replication/inventory", query: query)
    end

    def clusterInventory(includeSystem: nil)
      query = { "includeSystem": includeSystem }
      request("GET", "_api/replication/clusterInventory", query: query)
    end

    def logger
      request("GET", "_api/replication/logger-state")
    end

    def loggerFollow(from: nil, to: nil, chunkSize: nil, includeSystem: nil)
      query = {
        "from": from,
        "to":   to,
        "chunkSize":     chunkSize,
        "includeSystem": includeSystem
      }
      request("GET", "_api/replication/logger-follow", query: query)
    end

    def loggerFirstTick
      request("GET", "_api/replication/logger-first-tick", key: :firstTick)
    end

    def loggerRangeTick
      request("GET", "_api/replication/logger-tick-ranges")
    end

    def serverId
      request("GET", "_api/replication/server-id", key: :serverId)
    end

    def range
      request("GET", "_api/wal/range")
    end

    def lastTick
      request("GET", "_api/wal/lastTick")
    end

    def tail(from: nil, to: nil, global: nil, chunkSize: nil,
      serverID: nil, barrierID: nil)
      query = {
        from: from,
        to: to,
        global: global,
        chunkSize: chunkSize,
        serverID: serverID,
        barrierID: barrierID
      }
      request("GET", "_api/wal/tail", query: query)
    end

    def replication(master:, includeSystem: true,
      initialSyncMaxWaitTime: nil, incremental: nil,
      restrictCollections: nil, connectTimeout: nil,
      autoResync: nil, idleMinWaitTime: nil, requestTimeout: nil,
      requireFromPresent: nil, idleMaxWaitTime: nil, restrictType: nil,
      maxConnectRetries: nil, adaptivePolling: nil,
      connectionRetryWaitTime: nil, autoResyncRetries: nil, chunkSize: nil,
      verbose: nil)
      Arango::Replication.new(slave: self, master: master, includeSystem: includeSystem,
        initialSyncMaxWaitTime: initialSyncMaxWaitTime, incremental: incremental,
        restrictCollections: restrictCollections, connectTimeout: connectTimeout,
        autoResync: autoResync, idleMinWaitTime: idleMinWaitTime,
        requestTimeout: requestTimeout, requireFromPresent: requireFromPresent, idleMaxWaitTime: idleMaxWaitTime, restrictType: restrictType,
        maxConnectRetries: maxConnectRetries, adaptivePolling: adaptivePolling,
        connectionRetryWaitTime: connectionRetryWaitTime,
        autoResyncRetries: autoResyncRetries, chunkSize: chunkSize,
        verbose: verbose)
    end

    def replication_as_master(slave:, includeSystem: true,
      initialSyncMaxWaitTime: nil, incremental: nil,
      restrictCollections: nil, connectTimeout: nil,
      autoResync: nil, idleMinWaitTime: nil, requestTimeout: nil,
      requireFromPresent: nil, idleMaxWaitTime: nil, restrictType: nil,
      maxConnectRetries: nil, adaptivePolling: nil,
      connectionRetryWaitTime: nil, autoResyncRetries: nil, chunkSize: nil,
      verbose: nil)
      Arango::Replication.new(master: self, slave: slave, includeSystem: includeSystem,
        initialSyncMaxWaitTime: initialSyncMaxWaitTime, incremental: incremental,
        restrictCollections: restrictCollections, connectTimeout: connectTimeout,
        autoResync: autoResync, idleMinWaitTime: idleMinWaitTime,
        requestTimeout: requestTimeout, requireFromPresent: requireFromPresent, idleMaxWaitTime: idleMaxWaitTime, restrictType: restrictType,
        maxConnectRetries: maxConnectRetries, adaptivePolling: adaptivePolling,
        connectionRetryWaitTime: connectionRetryWaitTime,
        autoResyncRetries: autoResyncRetries, chunkSize: chunkSize,
        verbose: verbose)
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
      result = request("GET", "_api/foxx")
      return result if return_directly?(result)
      result.map do |fox|
        Arango::Foxx.new(database: self, mount: fox[:mount], body: fox)
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
      user.addDatabaseAccess(grant: grant, database: @name)
    end

    def revokeUserAccess(user:)
      user = check_user(user)
      user.revokeDatabaseAccess(database: @name)
    end

    def userAccess(user:)
      user = check_user(user)
      user.databaseAccess(database: @name)
    end

# === VIEW ===

    def views
      result = request("GET", "_api/view", key: :result)
      return result if return_directly?(result)
      result.map do |view|
        Arango::View.new(database: self, id: view[:id], name: view[:name], type: view[:type])
      end
    end

    def view(name:)
      Arango::View.new(database: self, name: name)
    end

# === TASK ===

    def task(id: nil, name: nil, type: nil, period: nil, command: nil, params: nil, created: nil, body: {})
      Arango::Task.new(id: id, name: name, type: type, period: period, command: command,
        params: params, created: created, body: body, database: self)
    end

    def tasks
      result = request("GET", "_api/tasks")
      return result if return_directly?(result)
      result.delete_if{|k| k[:database] != @name}
      result.map do |task|
        Arango::Task.new(body: task, database: self)
      end
    end

# === TRANSACTION ===

    def transaction(action:, write: [], read: [], params: nil,
      maxTransactionSize: nil, lockTimeout: nil, waitForSync: nil,
      intermediateCommitCount: nil, intermedateCommitSize: nil)
      Arango::Transaction.new(database: self, action: action, write: write,
        read: read, params: params, maxTransactionSize: maxTransactionSize,
        lockTimeout: lockTimeout, waitForSync: waitForSync,
        intermediateCommitCount: intermediateCommitCount,
        intermedateCommitSize: intermedateCommitSize)
    end
  end
end
