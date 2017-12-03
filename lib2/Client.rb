# === CLIENT ===

module Arango
  class Client
    def initialize(user: "root", password:, server: "localhost", port: "8529",
      verbose: false)
      @base_uri = "http://#{server}:#{port}"
      @verbose = verbose
      @server = server
      @port = port
      @username = user
      @async = false
      @options = {:body => {}, :headers => {}, :query => {}, :basic_auth => {:username => @username, :password => @password }}
    end

    attr_reader :username, :async, :server, :port
    attr_accessor :verbose, :cluster

    def request(action:, url:, body: {}, headers: {}, query: {},
      caseTrue: false, key: nil, return_direct_result: false,
      skip_to_json: false)
      send_url = "#{@base_uri}/url"
      puts "\n#{action} #{send_url}\n" if @verbose

      unless skip_to_json
        body.delete_if{|k,v| v.nil?}
        body = body.to_json
      end
      query.delete_if{|k,v| v.nil?}
      headers.delete_if{|k,v| v.nil?}

      options = @options.merge({:body => body, :query => query,
        :headers => headers})
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

      if @async == "store"
        return result.headers["x-arango-async-id"]
      elsif @async == true
        return true
      end
      if action == "HEAD"
        return result.headers
      end
      result = response.parsed_response
      puts result if @verbose
      if !result.is_a?(Hash) && !result.nil?
        raise Arango::Error message: "ArangoRB didn't return a valid hash", data: result
      elsif result.is_a?(Hash) && result["error"]
        raise Arango::Error message: result["errorMessage"]
      end
      return result if return_direct_result
      return true if caseTrue || action == "DELETE"
      return key.nil? ? result.delete_if{|k,v| k == "error" || k == "code"} : result[key]
    end

    def address
      "#{@server}:#{@port}"
    end

    def async=(async)
      if async == true || async == "true"
        @options[:headers]["x-arango-async"] = "true"
        @async = true
      elsif async == "store"
        @options[:headers]["x-arango-async"] ="store"
        @async = "store"
      else
        @options[:headers].delete("x-arango-async")
        @async = false
      end
    end

    def [](database)
      satisfy_class?(database, "database")
      Arango::Database.new(database: database, client: self)
    end
    alias database []

    def user(user)
      satisfy_class?(user, "user")
      Arango::User.new(user: user, client: self)
    end

# === MONITORING ===

    def log
      request(action: "GET", url: "/_admin/log")
    end

    def reload
      request(action: "POST", url: "/_admin/routing/reload", caseTrue: true)
    end

    def statistics description: false
      if description
        request(action: "GET", url: "/_admin/statistics-description")
      else
        request(action: "GET", url: "/_admin/statistics")
      end
    end

    def role
      request(action: "GET", url: "/_admin/server/role",  key: "role")
    end

    def server
      request(action: "GET", url: "/_admin/server/id")
    end

    def clusterStatistics dbserver:
      satisfy_class?(dbserver, "dbserver")
      query = {"DBserver": dbserver}
      request(action: "GET", url: "/_admin/clusterStatistics", query: query)
    end

# === LISTS ===

    def endpoints
      request(action: "GET", url: "/_api/endpoint")
    end

    def users
      result = request(action: "GET", url: "/_api/user")
      return result if @async != false
      result["result"].map do |user|
        Arango::User.new(user: user["user"], active: user["active"],
          extra: user["extra"], client: self)
      end
    end

    def databases(user: nil)
      satisfy_class?(user, "user", [NilClass, String, Arango::User])
      user = user.user if user.is_a?(Arango::User)
      if user.nil?
        result = request(action: "GET", url: "/_api/database")
      else
        result = request(action: "GET", url: "/_api/database/#{user}")
      end
      return result if @async != false
      result["result"].map do |db|
        Arango::Database.new(database: db, client: self)
      end
    end

    def tasks
      result = request(action: "GET", url: "/_api/tasks",
        return_direct_result: true)
      return result if @async != false
      result.map do |x|
        Arango::Task.new(id: x["id"], name: x["name"], type: x["type"],
          period: x["period"], created: x["created"],
          command: x["command"], database: x["database"], client: self)
      end
    end

# === ASYNC ===

    def pendingAsync
      result = request(action: "GET", url: "/_api/job/pending")
    end

    def fetchAsync(id:)
      satisfy_class?(id, "id")
      result = request(action: "PUT", url: "/_api/job/#{id}")
    end

    def retrieveAsync(type: nil, id: nil)
      if id.nil?
        request(action: "GET", url: "/_api/job/#{type}")
      else
        request(action: "GET", url: "/_api/job/#{id}")
      end
    end

    def retrieveDoneAsync
      retrieveAsync(type: "done")
    end

    def retrievePendingAsync
      retrieveAsync(type: "pending")
    end

    def cancelAsync(id:)
      request(action: "PUT", url: "/_api/job/#{id}/cancel")
    end

    def destroyAsync(type: nil, id: nil)
      if id.nil?
        request(action: "DELETE", url: "/_api/job/#{type}")
      else
        request(action: "DELETE", url: "/_api/job/#{id}")
      end
    end

    def destroyAllAsync
      destroyAsync(type: "all")
    end

    def destroyExpiredAsync
      destroyAsync(type: "expired")
    end

# === BATCH ===

    def batch(queries:)
      headers = {
        "Content-Type": "multipart/form-data",
        "boundary": "XboundaryX"
      }
      body = ""
      queries.each do |query|
        body += "--XboundaryX\n"
        body += "Content-Type: application/x-arango-batchpart\n"
        body += "Content-Id: #{query[:id]}\n" unless query[:id].nil?
        body += "\n"
        body += "#{query[:type]} "
        body += "#{query[:address]} HTTP/1.1\n"
        body += "\n#{query[:body].to_json}\n" unless query[:body].nil?
      end
      body += "--XboundaryX--\n" if queries.length > 0
      request(action: "POST", url: "/_api/batch", body: body,
        headers: headers, skip_to_json: true)
    end

    def destroyDumpBatch(id:, dbserver: nil)
      query = {"DBserver" => dbserver}
      request = @@request.merge({ :query => query })
      request(action: "DELETE", url: ("/_api/replication/batch/#{id}",
        query: query, return_direct_result: true)
    end

    def createDumpBatch(ttl:, dbserver: nil)
      query = {"DBserver" => dbserver}
      body = { "ttl" => ttl }
      request(action: "POST", url: ("/_api/replication/batch/",
        query: query, body: body, key: "id")
    end

    def prolongDumpBatch(id:, ttl:, dbserver: nil)
      query = {"DBserver" => dbserver}
      body = { "ttl" => ttl }
      request(action: "POST", url: ("/_api/replication/batch/#{id}",
        query: query, body: body, key: "id")
    end

# === REPLICATION ===

    def serverId
      request(action: "GET", url: "/_api/replication/server-id",
        key: "serverId")
    end

# === SHARDING ===

    def clusterRoundtrip(cluster: @cluster)
      request(action: "GET", url: "/_admin/#{cluster}")
    end

    def executeCluster(body:, cluster: @cluster)
      request(action: "POST", url: "/_admin/#{cluster}", body: body)
    end

    def executeClusterPut(body:, cluster: @cluster)
      request(action: "PUT", url: "/_admin/#{cluster}", body: body)
    end

    def destroyCluster(cluster: @cluster)
      request(action: "DELETE", url: "/_admin/#{cluster}")
    end

    def updateCluster(body:, cluster: @cluster)
      request(action: "PATCH", url: "/_admin/#{cluster}", body: body,
        caseTrue: true)
    end

    def executeClusterHead(body:, cluster: @cluster)
      request(action: "HEAD", url: "/_admin/#{cluster}")
    end

    def checkPort(port:)
      query = {"port": port}
      request(action: "GET", url: "/_admin/clusterCheckPort", query: query)
    end

    # === MISCELLANEOUS FUNCTIONS ===

    def version(details: nil)
      query = {"details": details}
      request(action: "GET", url: "/_api/version", query: query)
    end

    def flushWAL(waitForSync: nil, waitForCollector: nil)
      body = {
        "waitForSync" => waitForSync,
        "waitForCollector" => waitForCollector
      }
      request(action: "PUT", url: "/_admin/wal/flush", body: body,
        caseTrue: true)
    end

    def propertyWAL
      request(action: "GET", url: "/_admin/wal/properties")
    end

    def changePropertyWAL(allowOversizeEntries: nil, logfileSize: nil,
      historicLogfiles: nil, reserveLogfiles: nil, throttleWait: nil,
      throttleWhenPending: nil)
      body = {
        "allowOversizeEntries" => allowOversizeEntries,
        "logfileSize" => allowOversizeEntries,
        "historicLogfiles" => historicLogfiles,
        "reserveLogfiles" => reserveLogfiles,
        "throttleWait" => throttleWait,
        "throttleWhenPending" => throttleWhenPending
      }
      request(action: "PUT", url: "/_admin/wal/properties", body: body)
    end

    def transactions
      request(action: "GET", url: "/_admin/wal/transactions")
    end

    def time
      request(action: "GET", url: "/_admin/time", key: "time")
    end

    def echo
      request(action: "GET", url: "/_admin/echo")
    end

    def databaseVersion
      request(action: "GET", url: "/_admin/database/target-version",
        key: "version")
    end

    def sleep(duration:)
      query = {"duration": duration}
      request(action: "GET", url: "/_admin/sleep", query: query, key: "duration")
    end

    def shutdown
      request(action: "DELETE", url: "/_admin/shutdown")
    end

    def restart
      `sudo service arangodb restart`
    end

    def test(body:)
      request(action: "POST", url: "/_admin/test", body: body)
    end

    def execute(body:)
      request(action: "POST", url: "/_admin/execute", body: body)
    end

  # === UTILITY ===

    def return_result(result:, caseTrue: false, key: nil)
      return result.headers["x-arango-async-id"] if @@async == "store"
      return true if @@async
      result = result.parsed_response
      return result if @@verbose || !result.is_a?(Hash)
      return result["errorMessage"] if result["error"]
      return true if caseTrue
      return key.nil? ? result.delete_if{|k,v| k == "error" || k == "code"} : result[key]
    end

    def return_result_async(result:, caseTrue: false)
      result = result.parsed_response
      (@@verbose || !result.is_a?(Hash)) ? result : result["error"] ? result["errorMessage"] : caseTrue ? true : result.delete_if{|k,v| k == "error" || k == "code"}
    end
  end
end
