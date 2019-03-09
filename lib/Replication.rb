# === REPLICATION ===

module Arango
  class Replication
    include Arango::Helper_Error

    def initialize(master:, slave:, includeSystem: true,
      initialSyncMaxWaitTime: nil, incremental: nil,
      restrictCollections: nil, connectTimeout: nil,
      autoResync: nil, idleMinWaitTime: nil, requestTimeout: nil,
      requireFromPresent: nil, idleMaxWaitTime: nil, restrictType: nil,
      maxConnectRetries: nil, adaptivePolling: nil,
      connectionRetryWaitTime: nil, autoResyncRetries: nil, chunkSize: nil,
      verbose: nil)
      assign_master(master)
      assign_slave(slave)
      assign_restrictType(restrictType)
      assign_restrictCollections(restrictCollections)
      @includeSytem = includeSystem
      @initialSyncMaxWaitTime = initialSyncMaxWaitTime,
      @incremental = incremental
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
      @verbose = verbose
    end

    attr_accessor :endpoint, :username, :password, :includeSystem,
      :initialSyncMaxWaitTime, :incremental, :verbose, :connectTimeout,
      :autoResync, :idleMinWaitTime, :requestTimeout, :requireFromPresent,
      :idleMaxWaitTime, :maxConnectRetries, :adaptivePolling,
      :connectionRetryWaitTime, :autoResyncRetries, :chunkSize
    attr_reader :master, :slave, :restrictType, :restrictCollections

    def master=(master)
      satisfy_class?(master, [Arango::Database])
      @master = master
      @master_server = @master.server
    end
    alias assign_master master=

    def slave=(slave)
      satisfy_class?(slave, [Arango::Database])
      @slave = slave
      @slave_server = @slave.server
    end
    alias assign_slave slave=

    def restrictType=(restrictType)
      satisfy_category?(restrictType, ["include", "exclude", nil])
      @restrictType = restrictType
    end
    alias assign_restrictType restrictType=

    def restrictCollections=(restrictCollections)
      if restrictCollections.nil?
        @restrictCollections = nil
      else
        satisfy_class?(restrictCollections, [Arango::Collection, String], true)
        @restrictCollections = restrictCollections.map do |v|
          case v
          when String
            v
          when Arango::Collection
            v.name
          end
        end
      end
    end
    alias assign_restrictCollections restrictCollections=


    def to_h
      master
      {
        "master": {
          "database": @master.name,
          "username": @master_server.username,
          "endpoint": @master_server.endpoint
        },
        "slave": {
          "database": @slave.name,
          "username": @slave_server.username,
          "endpoint": @slave_server.endpoint
        },
        "options": {
          "includeSytem": @includeSystem,
          "initialSyncMaxWaitTime": @initialSyncMaxWaitTime,
          "restrictType": @restrictType,
          "incremental": @incremental,
          "restrictCollections": @restrictCollections,
          "verbose": @verbose,
          "connectTimeout": @connectTimeout,
          "autoResync": @autoResync,
          "idleMinWaitTime": @idleMinWaitTime,
          "requestTimeout": @requestTimeout,
          "requireFromPresent": @requireFromPresent,
          "idleMaxWaitTime": @idleMaxWaitTime,
          "maxConnectRetries": @maxConnectRetries,
          "adaptivePolling": @adaptivePolling,
          "connectionRetryWaitTime": @connectionRetryWaitTime,
          "autoResyncRetries": @autoResyncRetries,
          "chunkSize": @chunkSize
        }.delete_if{|k,v| v.nil?}
      }
    end

# SYNCRONISATION

    def sync
      body = {
        "username": @master_server.username,
        "password": @master_server.password,
        "endpoint": @master_server.endpoint,
        "database": @master.name,
        "restrictType":  @restrictType,
        "incremental":   @incremental,
        "includeSystem": @includeSystem,
        "restrictCollections":    @restrictCollections,
        "initialSyncMaxWaitTime": @initialSyncMaxWaitTime
      }
      @slave.request("PUT", "_api/replication/sync", body: body)
    end

# ENSLAVING

    def enslave
      body = {
        "username": @master_server.username,
        "password": @master_server.password,
        "includeSystem": @includeSystem,
        "endpoint":      @server.endpoint,
        "initialSyncMaxWaitTime": @initialSyncMaxWaitTime,
        "database":        @database.name,
        "verbose":         verbose,
        "connectTimeout":  @connectTimeout,
        "autoResync":      @autoResync,
        "idleMinWaitTime": @idleMinWaitTime,
        "requestTimeout":  @requestTimeout,
        "requireFromPresent": @requireFromPresent,
        "idleMaxWaitTime":   @idleMaxWaitTime,
        "restrictType":      @restrictType,
        "maxConnectRetries": @maxConnectRetries,
        "adaptivePolling":   @adaptivePolling,
        "connectionRetryWaitTime": @connectionRetryWaitTime,
        "restrictCollections":     @restrictCollections,
        "autoResyncRetries": @autoResyncRetries,
        "chunkSize":          @chunkSize
      }
      @slave.request("PUT", "_api/replication/make-slave", body: body)
    end

# REPLICATION

    def start(from: nil)
      @slave.request("PUT", "_api/replication/applier-start", query: {from: from})
    end

    def stop
      @slave.request("PUT", "_api/replication/applier-stop")
    end

    def state
      @slave.request("GET", "_api/replication/applier-state")
    end

    def configuration
      @slave.request("GET", "_api/replication/applier-config")
    end

    def modify
      body = {
        "username": @master_server.username,
        "password": @master_server.password,
        "endpoint": @master_server.endpoint,
        "database": @master.name,
        "verbose":  @verbose,
        "autoResync": @autoResync,
        "autoStart":  @autoStart,
        "chunkSize":  @chunkSize,
        "includeSystem":   @includeSystem,
        "connectTimeout":  @connectTimeout,
        "idleMinWaitTime": @idleMinWaitTime,
        "requestTimeout":  @requestTimeout,
        "restrictType":    @restrictType,
        "requireFromPresent":      @requireFromPresent,
        "idleMaxWaitTime":         @idleMaxWaitTime,
        "maxConnectRetries":       @maxConnectRetries,
        "adaptivePolling":         @adaptivePolling,
        "initialSyncMaxWaitTime":  @initialSyncMaxWaitTime,
        "connectionRetryWaitTime": @connectionRetryWaitTime,
        "restrictCollections":     @restrictCollections,
        "autoResyncRetries":       @autoResyncRetries
      }
      @slave.request("PUT", "_api/replication/applier-config", body: body)
    end
    alias modifyReplication modify

    # LOGGER

    def logger
      @slave.request("GET", "_api/replication/logger-state")
    end

    def loggerFollow(from: nil, to: nil, chunkSize: nil, includeSystem: nil)
      query = {
        "from": from,
        "to":   to,
        "chunkSize":     chunkSize,
        "includeSystem": includeSystem
      }
      @slave.request("GET", "_api/replication/logger-follow", query: query)
    end

    def loggerFirstTick
      @slave.request("GET", "_api/replication/logger-first-tick", key: :firstTick)
    end

    def loggerRangeTick
      @slave.request("GET", "_api/replication/logger-tick-ranges")
    end

    # SERVER-ID

    def serverId
      @slave.request("GET", "_api/replication/server-id", key: :serverId)
    end
  end
end
