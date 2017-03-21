# === REPLICATION ===

class ArangoReplication < ArangoServer
  def initialize(endpoint:, username:, password:, database: nil, includeSystem: true, initialSyncMaxWaitTime: nil, incremental: nil, restrictCollections: nil, verbose: false, connectTimeout: nil, autoResync: nil, idleMinWaitTime: nil, requestTimeout: nil, requireFromPresent: nil, idleMaxWaitTime: nil, restrictType: nil, maxConnectRetries: nil, adaptivePolling: nil, connectionRetryWaitTime: nil, autoResyncRetries: nil, chunkSize: nil)
    if database.is_a?(String) || database.nil?
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be nil, a String or an ArangoDatabase instance, not a #{database.class}"
    end

    if restrictType == "include" || restrictType == "exclude" || restrictType.nil?
      @restrictType = restrictType
    else
      raise "restrictType can be only \"include\" or \"exclude\"."
    end

    if restrictCollections.nil?
      @restrictCollections = nil
    else
      @restrictCollections = []
      restrictCollections.each do |v|
        if v.is_a? (String)
          @restrictCollections << v
        elsif v.is_a? (ArangoCollection)
          @restrictCollections << v.name
        end
      end
    end

    @endpoint = endpoint
    @username = username
    @password = password
    @includeSytem = includeSystem
    @initialSyncMaxWaitTime = initialSyncMaxWaitTime,
    @incremental = incremental
    @verbose = verbose,
    @connectTimeout = connectTimeout
    @autoResync = autoResync
    @idleMinWaitTime = idleMinWaitTime
    @requestTimeout = requestTimeout
    @requireFromPresent = requireFromPresent
    @idleMaxWaitTime = idleMaxWaitTime
    @maxConnectRetries = maxConnectRetries
    @adaptivePolling = adaptivePolling
    @connectionRetryWaitTime = connectionRetryWaitTime
    @autoResyncRetries = autoResyncRetries
    @chunkSize = chunkSize
  end

  def master(endpoint:, username:, password:, database: nil)
    if database.is_a?(String) || database.nil?
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be nil, a String or an ArangoDatabase instance, not a #{database.class}"
    end

    @endpoint = endpoint
    @username = username
    @password = password
  end

  attr_accessor :endpoint, :username, :password, :includeSystem, :initialSyncMaxWaitTime, :incremental, :verbose, :connectTimeout, :autoResync, :idleMinWaitTime, :requestTimeout, :requireFromPresent, :idleMaxWaitTime, :maxConnectRetries, :adaptivePolling, :connectionRetryWaitTime, :autoResyncRetries, :chunkSize
  attr_reader :database, :restrictType, :restrictCollections

  def restrictType=(value)
    if value == "include" || value == "exclude" || value.nil?
      @restrictType = value
    else
      raise "restrictType can be only \"include\" or \"exclude\"."
    end
  end

  def restrictCollections=(value)
    if value.nil?
      @restrictCollections = nil
    else
      value = [value] unless value.is_a? Array
      @restrictCollections = []
      value.each do |v|
        if v.is_a? (String)
          @restrictCollections << v
        elsif v.is_a? (ArangoCollection)
          @restrictCollections << v.name
        end
      end
    end
  end

  def to_hash
    master
    {
      "master" => {
        "endpoint" => @endpoint,
        "username" => @username,
        "password" => @password,
        "database" => @database
      }.delete_if{|k,v| v.nil?},
      "options" => {
        "includeSytem" => @includeSystem,
        "initialSyncMaxWaitTime" => @initialSyncMaxWaitTime,
        "restrictType" => @restrictType,
        "incremental" => @incremental,
        "restrictCollections" => @restrictCollections,
        "verbose" => @verbose,
        "connectTimeout" => @connectTimeout,
        "autoResync" => @autoResync,
        "idleMinWaitTime" => @idleMinWaitTime,
        "requestTimeout" => @requestTimeout,
        "requireFromPresent" => @requireFromPresent,
        "idleMaxWaitTime" => @idleMaxWaitTime,
        "maxConnectRetries" => @maxConnectRetries,
        "adaptivePolling" => @adaptivePolling,
        "connectionRetryWaitTime" => @connectionRetryWaitTime,
        "autoResyncRetries" => @autoResyncRetries,
        "chunkSize" => @chunkSize
      }.delete_if{|k,v| v.nil?}
    }
  end
  alias to_h to_hash

# SYNCRONISATION

  def sync
    body = {
      "username" => @username,
      "password" => @password,
      "endpoint" => @endpoint,
      "database" => @database,
      "includeSystem" => @includeSystem,
      "initialSyncMaxWaitTime" => @initialSyncMaxWaitTime,
      "restrictType" => @restrictType,
      "incremental" => @incremental,
      "restrictCollections" => @restrictCollections
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_api/replication/sync", request)
    self.class.return_result result: result
  end

# ENSLAVE

  def enslave
    body = {
      "username" => @username,
      "password" => @password,
      "endpoint" => @endpoint,
      "database" => @database,
      "includeSystem" => @includeSystem,
      "initialSyncMaxWaitTime" => @initialSyncMaxWaitTime,
      "verbose" => @verbose,
      "connectTimeout" => @connectTimeout,
      "autoResync" => @autoResync,
      "idleMinWaitTime" => @idleMinWaitTime,
      "requestTimeout" => @requestTimeout,
      "requireFromPresent" => @requireFromPresent,
      "idleMaxWaitTime" => @idleMaxWaitTime,
      "restrictType" => @restrictType,
      "maxConnectRetries" => @maxConnectRetries,
      "adaptivePolling" => @adaptivePolling,
      "connectionRetryWaitTime" => @connectionRetryWaitTime,
      "restrictCollections" =>  @restrictCollections,
      "autoResyncRetries" => @autoResyncRetries,
      "chunkSize" => @chunkSize
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_api/replication/make-slave", request)
    self.class.return_result result: result
  end

# MANAGE CONFIGURATION

  def stateReplication # TESTED
    result = self.class.get("/_db/#{@database}/_api/replication/applier-state", @@request)
    self.class.return_result result: result
  end

  def configurationReplication
    result = self.class.get("/_api/replication/applier-config", @@request)
    self.class.return_result result: result
  end

  def modifyConfigurationReplication
    body = {
      "username" => @username,
      "password" => @password,
      "includeSystem" => @includeSystem,
      "endpoint" => @endpoint,
      "initialSyncMaxWaitTime" => @initialSyncMaxWaitTime,
      "database" => @database,
      "verbose" => @verbose,
      "connectTimeout" => @connectTimeout,
      "autoResync" => @autoResync,
      "idleMinWaitTime" => @idleMinWaitTime,
      "requestTimeout" => @requestTimeout,
      "requireFromPresent" => @requireFromPresent,
      "idleMaxWaitTime" => @idleMaxWaitTime,
      "restrictType" => @restrictType,
      "maxConnectRetries" => @maxConnectRetries,
      "autoStart" => @autoStart,
      "adaptivePolling" => @adaptivePolling,
      "connectionRetryWaitTime" => @connectionRetryWaitTime,
      "restrictCollections" => @restrictCollections,
      "autoResyncRetries" => @autoResyncRetries,
      "chunkSize" => @chunkSize
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_api/replication/applier-config", request)
    self.class.return_result result: result
  end
  alias modifyReplication modifyConfigurationReplication

  def startReplication(from: nil) # TESTED
    query = {from: from}.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.put("/_api/replication/applier-start", request)
    self.class.return_result result: result
  end

  def stopReplication # TESTED
    result = self.class.put("/_api/replication/applier-stop", @@request)
    self.class.return_result result: result
  end

# INFO

  def serverId # TESTED
    result = self.class.get("/_db/#{@database}/_api/replication/server-id", @@request)
    self.class.return_result result: result, key: "serverId"
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
end
