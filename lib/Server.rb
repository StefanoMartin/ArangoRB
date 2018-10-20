# === SERVER ===

module Arango
  class Server
    include Arango::Helper_Error

    def initialize(username: "root", password:, server: "localhost",
      warning: true, port: "8529", verbose: false, return_output: false,
      cluster: nil, async: false, active_cache: true)
      @base_uri = "http://#{server}:#{port}"
      @server = server
      @port = port
      @username = username
      @password = password
      @options = {body: {}, headers: {}, query: {},
        basic_auth: {username: @username, password: @password }, format: :plain}
      assign_async(async)
      @verbose = verbose
      @return_output = return_output
      @cluster = cluster
      @warning = warning
      @active_cache = active_cache
      @cache = @active_cache ? Arango::Cache.new : nil
    end

# === DEFINE ===

    attr_reader :async, :port, :server, :base_uri, :username, :cache, :active_cache
    attr_accessor :cluster, :verbose, :return_output, :warning

    def active_cache=(active)
      satisfy_category?(active, [true, false])
      @active_cache = active
      if @active_cache
        @cache ||= Arango::Cache.new
      elsif !@cache.nil?
        @cache.clear
      end
    end

    def username=(username)
      @username = username
      @options[:basic_auth][:username] = @username
    end

    def password=(password)
      @password = password
      @options[:basic_auth][:password] = @password
    end

    def port=(port)
      @port = port
      @base_uri = "http://#{@server}:#{@port}"
    end

    def server=(server)
      @server = server
      @base_uri = "http://#{@server}:#{@port}"
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
    end
    alias assign_async async=

# === TO HASH ===

    def to_h(level=0)
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
      }
      hash.delete_if{|k,v| v.nil?}
      hash
    end

# === REQUESTS ===

    def download(url:, path:, body: {}, headers: {}, query: {}, skip_cluster: false)
      send_url = "#{@base_uri}/"
      if !@cluster.nil? && !skip_cluster
        send_url += "_admin/#{@cluster}/"
      end
      send_url += url
      body.delete_if{|k,v| v.nil?}
      query.delete_if{|k,v| v.nil?}
      headers.delete_if{|k,v| v.nil?}
      body = Oj.dump(body, mode: :json)
      options = @options.merge({body: body, query: query, headers: headers, stream_body: true})
      puts "\n#{action} #{send_url}\n" if @verbose
      File.open(path, "w") do |file|
        file.binmode
        HTTParty.post(send_url, options) do |fragment|
          file.write(fragment)
        end
      end
    end

    def request(action, url, body: {}, headers: {}, query: {},
      key: nil, return_direct_result: @return_output, skip_to_json: false,
      skip_cluster: false, keepNull: false, skip_parsing: false)
      send_url = "#{@base_uri}/"
      if !@cluster.nil? && !skip_cluster
        send_url += "_admin/#{@cluster}/"
      end
      send_url += url

      if body.is_a?(Hash)
        body.delete_if{|k,v| v.nil?} unless keepNull
      end
      query.delete_if{|k,v| v.nil?}
      headers.delete_if{|k,v| v.nil?}
      options = @options.merge({body: body, query: query})
      options[:headers].merge!(headers)

      if ["GET", "HEAD", "DELETE"].include?(action)
        options.delete(:body)
      end

      if @verbose
        puts "\n===REQUEST==="
        puts "#{action} #{send_url}\n"
        puts JSON.pretty_generate(options)
        puts "==============="
      end

      if !skip_to_json && !options[:body].nil?
        options[:body] = Oj.dump(options[:body], mode: :json)
      end
      options.delete_if{|k,v| v.empty?}

      response = case action
      when "GET"
        HTTParty.get(send_url, options)
      when "HEAD"
        HTTParty.head(send_url, options)
      when "PATCH"
        HTTParty.patch(send_url, options)
      when "POST"
        HTTParty.post(send_url, options)
      when "PUT"
        HTTParty.put(send_url, options)
      when "DELETE"
        HTTParty.delete(send_url, options)
      end

      if @verbose
        puts "\n===RESPONSE==="
        puts "CODE: #{response.code}"
      end

      case @async
      when :store
        val = response.headers["x-arango-async-id"]
        if @verbose
          puts val
          puts "==============="
        end
        return val
      when true
        puts "===============" if @verbose
        return true
      end

      if skip_parsing
        val = response.parsed_response
        if @verbose
          puts val
          puts "==============="
        end
        return val
      end

      begin
        result = Oj.load(response.parsed_response, mode: :json, symbol_keys: true)
      rescue Exception => e
        raise Arango::Error.new err: :impossible_to_parse_arangodb_response,
          data: {"response": response.parsed_response, "action": action, "url": send_url,
            "request": JSON.pretty_generate(options)}
      end

      if @verbose
        if result.is_a?(Hash) || result.is_a?(Array)
          puts JSON.pretty_generate(result)
        else
          puts "#{result}\n"
        end
        puts "==============="
      end

      if ![Hash, NilClass, Array].include?(result.class)
        raise Arango::Error.new message: "ArangoRB didn't return a valid result", data: {"response": response, "action": action, "url": send_url, "request": JSON.pretty_generate(options)}
      elsif result.is_a?(Hash) && result[:error]
        raise Arango::ErrorDB.new message: result[:errorMessage],
          code: result[:code], data: result, errorNum: result[:errorNum],
          action: action, url: send_url, request: options
      end
      if return_direct_result || @return_output || !result.is_a?(Hash)
        return result
      end
      return key.nil? ? result.delete_if{|k,v| k == :error || k == :code}: result[key]
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
