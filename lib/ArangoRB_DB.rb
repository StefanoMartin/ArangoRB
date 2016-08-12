# === DATABASE ===

class ArangoDatabase < ArangoServer
  def initialize(database: @@database)  # TESTED
    if database.is_a?(String)
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be a String or an ArangoDatabase instance, not a #{database.class}"
    end
  end

  attr_reader :database # TESTED
  alias name database

  # === RETRIEVE ===

  def [](collection_name)
    ArangoCollection.new(collection: collection_name, database: @database)
  end
  alias collection []

  def graph(graph_name)
     ArangoGraph.new(graph: graph_name, database: @database)
  end

  # === GET ===

  def info  # TESTED
    result = self.class.get("/_db/#{@database}/_api/database/current", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].delete_if{|k,v| k == "error" || k == "code"}
  end

  # === POST ===

  def create(username: nil, passwd: nil, users: nil)  # TESTED
    body = {
      "name" => @database,
      "username" => username,
      "passwd" => passwd,
      "users" => users
    }
    body = body.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_api/database", request)
    @@async == "store" ? result.headers["x-arango-async-id"] : @@verbose ? result.parsed_response : result.parsed_response["error"] ? result.parsed_response["errorMessage"] : self
  end

  # === DELETE ===

  def destroy  # TESTED
    result = self.class.delete("/_api/database/#{@database}", @@request)
    self.class.return_result(result: result, caseTrue: true)
  end

  # === LISTS ===

  def self.databases(user: nil)  # TESTED
    user = user.user if user.is_a?(ArangoUser)
    result = user.nil? ? get("/_api/database") : get("/_api/database/#{user}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].map{|x| ArangoDatabase.new(database: x)}
  end

  def collections(excludeSystem: true)  # TESTED
    query = { "excludeSystem": excludeSystem }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/collection", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].map{|x| ArangoCollection.new(database: @database, collection: x["name"])}
  end

  def graphs  # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["graphs"].map{|x| ArangoGraph.new(database: @database, graph: x["_key"], edgeDefinitions: x["edgeDefinitions"], orphanCollections: x["orphanCollections"])}
  end

  def functions  # TESTED
    result = self.class.get("/_db/#{@database}/_api/aqlfunction", @@request)
    self.class.return_result result: result
  end

  # === QUERY ===

  def propertiesQuery  # TESTED
    result = self.class.get("/_db/#{@database}/_api/query/properties", @@request)
    self.class.return_result result: result
  end

  def currentQuery  # TESTED
    result = self.class.get("/_db/#{@database}/_api/query/current", @@request)
    self.class.return_result result: result
  end

  def slowQuery  # TESTED
    result = self.class.get("/_db/#{@database}/_api/query/slow", @@request)
    self.class.return_result result: result
  end

  def stopSlowQuery  # TESTED
    result = self.class.delete("/_db/#{@database}/_api/query/slow", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  def killQuery(query:)  # TESTED
    id = query.is_a?(ArangoAQL) ? query.id : query.is_a?(String) ? query : nil
    result = self.class.delete("/_db/#{@database}/_api/query/#{id}", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  def changePropertiesQuery(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil)  # TESTED
    body = {
      "slowQueryThreshold" => slowQueryThreshold,
      "enabled" => enabled,
      "maxSlowQueries" => maxSlowQueries,
      "trackSlowQueries" => trackSlowQueries,
      "maxQueryStringLength" => maxQueryStringLength
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/query/properties", request)
    self.class.return_result result: result
  end

# === CACHE ===

  def clearCache  # TESTED
    result = self.class.delete("/_db/#{@database}/_api/query-cache", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  def propertyCache  # TESTED
    result = self.class.get("/_db/#{@database}/_api/query-cache/properties", @@request)
    self.class.return_result result: result
  end

  def changePropertyCache(mode: nil, maxResults: nil)  # TESTED
    body = { "mode" => mode, "maxResults" => maxResults }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/query-cache/properties", request)
    self.class.return_result result: result
  end

  # === AQL FUNCTION ===

  def createFunction(code:, name:, isDeterministic: nil)  # TESTED
    body = {
      "code" => code,
      "name" => name,
      "isDeterministic" => isDeterministic
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/aqlfunction", request)
    self.class.return_result result: result
  end

  def deleteFunction(name:) # TESTED
    result = self.class.delete("/_db/#{@database}/_api/aqlfunction/#{name}", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  # === REPLICATION ===

  def inventory(includeSystem: false) # TESTED
    query = { "includeSystem": includeSystem }
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/replication/inventory", request)
    self.class.return_result result: result
  end

  def clusterInventory(includeSystem: false) # TESTED
    query = { "includeSystem": includeSystem }
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/replication/clusterInventory", request)
    self.class.return_result result: result
  end

  def logger # TESTED
    result = self.class.get("/_db/#{@database}/_api/replication/logger-state")
    self.class.return_result result: result
  end

  def loggerFollow(from: nil, to: nil, chunkSize: nil, includeSystem: false) # TESTED
    query = {
      "from": from,
      "to": to,
      "chunkSize": chunkSize,
      "includeSystem": includeSystem
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/replication/logger-follow", request)
    self.class.return_result result: result
  end

  def firstTick # TESTED
    result = self.class.get("/_db/#{@database}/_api/replication/logger-first-tick")
    self.class.return_result result: result, key: "firstTick"
  end

  def rangeTick # TESTED
    result = self.class.get("/_db/#{@database}/_api/replication/logger-tick-ranges")
    self.class.return_result result: result
  end

  def sync(endpoint: "tcp://#{@@server}:#{@@port}", username: @@username, password: @@password, includeSystem: false, database: @database, initialSyncMaxWaitTime: nil, restrictType: nil, incremental: nil, restrictCollections: nil)
    body = {
      "username" => username,
      "password" => password,
      "includeSystem" => includeSystem,
      "endpoint" => endpoint,
      "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
      "database" => database,
      "restrictType" => restrictType,
      "incremental" => incremental,
      "restrictCollections" =>  restrictCollections
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{database}/_api/replication/sync", request)
    self.class.return_result result: result
  end

  def configurationReplication # TESTED
    result = self.class.get("/_db/#{@database}/_api/replication/applier-config", @@request)
    self.class.return_result result: result
  end

  def modifyConfigurationReplication(endpoint: "tcp://#{@@server}:#{@@port}", username: @@username, password: @@password, database: @database, includeSystem: false, verbose: false, connectTimeout: nil, autoResync: nil, idleMinWaitTime: nil, requestTimeout: nil, requireFromPresent: nil, idleMaxWaitTime: nil, restrictCollections: nil, restrictType: nil, initialSyncMaxWaitTime: nil, maxConnectRetries: nil, autoStart: nil, adaptivePolling: nil, connectionRetryWaitTime: nil, autoResyncRetries: nil, chunkSize: nil) # TESTED
    body = {
      "username" => username,
      "password" => password,
      "includeSystem" => includeSystem,
      "endpoint" => endpoint,
      "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
      "database" => database,
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
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{database}/_api/replication/applier-config", request)
    self.class.return_result result: result
  end

  def startReplication(from: nil)
    query = {from: from}.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.put("/_db/#{@database}/_api/replication/applier-start", request)
    self.class.return_result result: result
  end

  def stopReplication
    result = self.class.put("/_db/#{@database}/_api/replication/applier-stop", @@request)
    self.class.return_result result: result
  end

  def stateReplication
    result = self.class.get("/_db/#{@database}/_api/replication/applier-state", @@request)
    self.class.return_result result: result
  end

  def enslave(username: @@username, includeSystem: false, endpoint: "tcp://#{@@server}:#{@@port}", verbose: false, connectTimeout: nil, autoResync: nil, password: @@password, database: @database,  idleMinWaitTime: nil, requestTimeout: nil, requireFromPresent: nil, idleMaxWaitTime: nil, restrictCollections: nil, restrictType: nil, initialSyncMaxWaitTime: nil, maxConnectRetries: nil, adaptivePolling: nil, connectionRetryWaitTime: nil, autoResyncRetries: nil, chunkSize: nil)
    body = {
      "username" => username,
      "password" => password,
      "includeSystem" => includeSystem,
      "endpoint" => endpoint,
      "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
      "database" => database,
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
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/replication/make-slave", request)
    self.class.return_result result: result
  end

  # === USER ===

  def grant(user: @@user) # TESTED
    user = user.user if user.is_a?(ArangoUser)
    body = { "grant" => "rw" }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_api/user/#{user}/database/#{@database}", request)
    self.class.return_result result: result, caseTrue: true
  end

  def revoke(user: @@user) # TESTED
    user = user.user if user.is_a?(ArangoUser)
    body = { "grant" => "none" }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_api/user/#{user}/database/#{@database}", request)
    self.class.return_result result: result, caseTrue: true
  end
end
