# === SERVER ===

module Arango
  class Server
    include Arango::Helper_Error

    def initialize(username: "root", password:, server: "localhost",
      warning: true, port: "8529", verbose: false, return_output: false, cluster: nil, async: false, active_cache: true, pool: false, size: 5, timeout: 5)
      @base_uri = "http://#{server}:#{port}"
      @server = server
      @port = port
      @username = username
      @password = password
      @options = {body: {}, headers: {}, query: {},
        basic_auth: {username: @username, password: @password }, format: :plain}
      @verbose = verbose
      @return_output = return_output
      @cluster = cluster
      @warning = warning
      @active_cache = active_cache
      @cache = @active_cache ? Arango::Cache.new : nil
      @pool = pool
      @size = size
      @timeout = timeout
      @request = Arango::Request.new(return_output: @return_output,
        base_uri: @base_uri, cluster: @cluster, options: @options, verbose: @verbose, async: @async)
      assign_async(async)
      if @pool
        @internal_request = ConnectionPool.new(size: @size, timeout: @timeout){ @request }
      end
    end

# === DEFINE ===

    attr_reader :async, :port, :server, :base_uri, :username, :cache, :cluster,
      :verbose, :return_output, :active_cache, :pool
    attr_accessor :warning, :size, :timeout

    def active_cache=(active)
      satisfy_category?(active, [true, false])
      @active_cache = active
      if @active_cache
        @cache ||= Arango::Cache.new
      elsif !@cache.nil?
        @cache.clear
      end
    end

    def pool=(pool)
      satisfy_category?(pool, [true, false])
      return if @pool == pool
      @pool = pool
      if @pool
        @internal_request = ConnectionPool.new(size: @size, timeout: @timeout){ @request }
      else
        @internal_request&.shutdown { |conn| conn.quit }
        @internal_request = nil
      end
    end
    alias changePoolStatus pool=

    def restartPool
      changePoolStatus(false)
      changePoolStatus(true)
    end

    def verbose=(verbose)
      satisfy_category?(verbose, [true, false])
      @verbose = verbose
      @request.verbose = verbose
    end

    def cluster=(cluster)
      @cluster = cluster
      @request.cluster = cluster
    end

    def return_output=(return_output)
      satisfy_category?(return_output, [true, false])
      @return_output = return_output
      @request.return_output = return_output
    end

    def username=(username)
      @username = username
      @options[:basic_auth][:username] = @username
      @request.options = options
    end

    def password=(password)
      @password = password
      @options[:basic_auth][:password] = @password
      @request.options = options
    end

    def port=(port)
      @port = port
      @base_uri = "http://#{@server}:#{@port}"
      @request.base_uri = @base_uri
    end

    def server=(server)
      @server = server
      @base_uri = "http://#{@server}:#{@port}"
      @request.base_uri = @base_uri
    end

    def async=(async)
      satisfy_category?(async, ["true", "false", false, true, "store", :store])
      case async
      when true, "true"
        @options[:headers]["x-arango-async"] = "true"
        @async = true
      when :store, "store"
        @options[:headers]["x-arango-async"] ="store"
        @async = :store
      when false, "false"
        @options[:headers].delete("x-arango-async")
        @async = false
      end
      @request.async = @async
      @request.options = @options
    end
    alias assign_async async=

# === TO HASH ===

    def to_h
      hash = {
        "base_uri": @base_uri,
        "server":   @server,
        "port":     @port,
        "username": @username,
        "async":    @async,
        "verbose":  @verbose,
        "return_output": @return_output,
        "cluster": @cluster,
        "warning": @warning
      }.delete_if{|k,v| v.nil?}
    end

# === REQUESTS ===

    def request(*args)
      if @pool
        @internal_request.with{|request| request.request(*args)}
      else
        @request.request(*args)
      end
    end

    def download(*args)
      if @pool
        @internal_request.with{|request| request.download(*args)}
      else
        @request.download(*args)
      end
    end

  #  == DATABASE ==

    def [](database)
      Arango::Database.new(name: database, server: self)
    end

    def database(name:)
      Arango::Database.new(name: name, server: self)
    end

    def databases(user: false)
      if user
        result = request("GET", "_api/database/user", key: :result)
      else
        result = request("GET", "_api/database", key: :result)
      end
      return result if return_directly?(result)
      result.map{|db| Arango::Database.new(name: db, server: self)}
    end

  # == CLUSTER ==

    def checkPort(port: @port)
      request("GET", "_admin/clusterCheckPort", query: {port: port.to_s})
    end

  # === MONITORING ===

    def log(upto: nil, level: nil, start: nil, size: nil, offset: nil, search: nil, sort: nil)
      satisfy_category?(upto, [nil, "fatal", 0, "error", 1, "warning", 2, "info", 3, "debug", 4])
      satisfy_category?(sort, [nil, "asc", "desc"])
      query = {
        upto: upto, level: level, start: start, size: size,
        offset: offset, search: search, sort: sort
      }
      request("GET", "_admin/log", query: query, skip_cluster: true)
    end

    def loglevel
      request("GET", "_admin/log/level", skip_cluster: true)
    end

    def updateLoglevel(body:)
      request("PUT", "_admin/log/level", skip_cluster: true, body: body)
    end

    def reload
      request("GET", "_admin/server/availability", skip_cluster: true)
      return true
    end

    def available?
      request("POST", "_admin/routing/reload", body: {}, skip_cluster: true)
    end

    def statistics
      request("GET", "_admin/statistics", skip_cluster: true)
    end

    def statisticsDescription
      request("GET", "_admin/statistics-description", skip_cluster: true)
    end

    def status
      request("GET", "_admin/status", skip_cluster: true)
    end

    def role
      request("GET", "_admin/server/role", skip_cluster: true, key: :role)
    end

    def serverData
      request("GET", "_admin/server/id", skip_cluster: true)
    end

    def mode
      request("GET", "_admin/server/mode", skip_cluster: true)
    end

    def updateMode(mode:)
      satisfy_category?(mode, ["default", "readonly"])
      body = {mode: mode}
      request("PUT", "_admin/server/mode", body: mode, skip_cluster: true)
    end

    def clusterHealth
      request("GET", "_admin/health", skip_cluster: true)
    end

    def clusterStatistics dbserver:
      query = {DBserver: dbserver}
      request("GET", "_admin/clusterStatistics", query: query, skip_cluster: true)
    end

  # === ENDPOINT ===

    def endpoint
      "tcp://#{@server}:#{@port}"
    end

    def endpoints
      request("GET", "_api/cluster/endpoints")
    end

    def allEndpoints(warning: @warning)
      warning_deprecated(warning, "allEndpoints")
      request("GET", "_api/endpoint")
    end

  # === USER ===

    def user(password: "", name:, extra: {}, active: nil)
      Arango::User.new(server: self, password: password, name: name, extra: extra,
        active: active)
    end

    def users
      result = request("GET", "_api/user", key: :result)
      return result if return_directly?(result)
      result.map do |user|
        Arango::User.new(name: user[:user], active: user[:active],
          extra: user[:extra], server: self)
      end
    end

  # == TASKS ==

    def tasks
      result = request("GET", "_api/tasks")
      return result if return_directly?(result)
      result.map do |task|
        database = Arango::Database.new(name: task[:database], server: self)
        Arango::Task.new(body: task, database: database)
      end
    end

# === ASYNC ===

    def fetchAsync(id:)
      request("PUT", "_api/job/#{id}")
    end

    def cancelAsync(id:)
      request("PUT", "_api/job/#{id}/cancel", key: :result)
    end

    def destroyAsync(id:, stamp: nil)
      query = {"stamp": stamp}
      request("DELETE", "_api/job/#{id}", query: query, key: :result)
    end

    def destroyAsyncByType(type:, stamp: nil)
      satisfy_category?(type, ["all", "expired"])
      query = {"stamp": stamp}
      request("DELETE", "_api/job/#{type}", query: query)
    end

    def destroyAllAsync
      destroyAsyncByType(type: "all")
    end

    def destroyExpiredAsync
      destroyAsyncByType(type: "expired")
    end

    def retrieveAsync(id:)
      request("GET", "_api/job/#{id}")
    end

    def retrieveAsyncByType(type:, count: nil)
      satisfy_category?(type, ["done", "pending"])
      request("GET", "_api/job/#{type}", query: {count: count})
    end

    def retrieveDoneAsync(count: nil)
      retrieveAsyncByType(type: "done", count: count)
    end

    def retrievePendingAsync(count: nil)
      retrieveAsyncByType(type: "pending", count: count)
    end

  # === BATCH ===

    def batch(boundary: "XboundaryX", queries: [])
      Arango::Batch.new(server: self, boundary: boundary, queries: queries)
    end

    def createDumpBatch(ttl:, dbserver: nil)
      query = { DBserver: dbserver }
      body = { ttl: ttl }
      result = request("POST", "_api/replication/batch",
        body: body, query: query)
      return result if return_directly?(result)
      return result[:id]
    end

    def destroyDumpBatch(id:, dbserver: nil)
      query = {DBserver: dbserver}
      result = request("DELETE", "_api/replication/batch/#{id}", query: query)
      return_delete(result)
    end

    def prolongDumpBatch(id:, ttl:, dbserver: nil)
      query = { DBserver: dbserver }
      body  = { ttl: ttl }
      result = request("PUT", "_api/replication/batch/#{id}",
        body: body, query: query)
      return result if return_directly?(result)
      return true
    end

  # === AGENCY ===

    def agencyConfig
      request("GET", "_api/agency/config")
    end

    def agencyWrite(body:, agency_mode: nil)
      satisfy_category?(agency_mode, ["waitForCommmitted", "waitForSequenced", "noWait", nil])
      headers = {"X-ArangoDB-Agency-Mode": agency_mode}
      request("POST", "_api/agency/write", headers: headers,
        body: body)
    end

    def agencyRead(body:, agency_mode: nil)
      satisfy_category?(agency_mode, ["waitForCommmitted", "waitForSequenced", "noWait", nil])
      headers = {"X-ArangoDB-Agency-Mode": agency_mode}
      request("POST", "_api/agency/read", headers: headers,
        body: body)
    end

# === MISCELLANEOUS FUNCTIONS ===

    def version(details: nil)
      query = {"details": details}
      request("GET", "_api/version", query: query)
    end

    def engine
      request("GET", "_api/engine")
    end

    def flushWAL(waitForSync: nil, waitForCollector: nil)
      body = {
        "waitForSync": waitForSync,
        "waitForCollector": waitForCollector
      }
      result = request("PUT", "_admin/wal/flush", body: body)
      return return_directly?(result) ? result: true
    end

    def propertyWAL
      request("GET", "_admin/wal/properties")
    end

    def changePropertyWAL(allowOversizeEntries: nil, logfileSize: nil,
      historicLogfiles: nil, reserveLogfiles: nil, throttleWait: nil,
      throttleWhenPending: nil)
      body = {
        "allowOversizeEntries": allowOversizeEntries,
        "logfileSize": allowOversizeEntries,
        "historicLogfiles": historicLogfiles,
        "reserveLogfiles": reserveLogfiles,
        "throttleWait": throttleWait,
        "throttleWhenPending": throttleWhenPending
      }
      request("PUT", "_admin/wal/properties", body: body)
    end

    def transactions
      request("GET", "_admin/wal/transactions")
    end

    def time
      request("GET", "_admin/time", key: :time)
    end

    def echo
      request("POST", "_admin/echo", body: {})
    end

    # def echo
    #   request("GET", "_admin/long_echo")
    # end

    def databaseVersion
      request("GET", "_admin/database/target-version", key: :version)
    end

    def shutdown
      result = request("DELETE", "_admin/shutdown")
      return return_directly?(result) ? result: true
    end

    def test(body:)
      request("POST", "_admin/test", body: body)
    end

    def execute(body:)
      request("POST", "_admin/execute", body: body)
    end

    def return_directly?(result)
      return @async != false || @return_direct_result
      return result if result == true
    end

    def return_delete(result)
      return result if @async != false
      return return_directly?(result) ? result : true
    end
  end
end
