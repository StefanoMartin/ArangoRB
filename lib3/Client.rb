# === CLIENT ===

module Arango
  class Client
    def initialize(username: "root", password:, server: "localhost",
      port: "8529", verbose: false, return_output: false, initialize_retrieve: true)
      @base_uri = "http://#{server}:#{port}"
      @server = server
      @port = port
      @username = username
      @async = false
      @options = {:body => {}, :headers => {}, :query => {},
      :basic_auth => {:username => @username, :password => @password }}
      @verbose = verbose
      @return_output = return_output
      @initialize_retrieve = initialize_retrieve
    end

    attr_reader :username, :async, :server, :port, :verbose, :return_output, :initialize_retrieve
    attr_accessor :cluster

    def to_h
      {
        "base_uri" => @base_uri
        "server" => @server,
        "port" => @port,
        "username" => @username,
        "async" => @async,
        "verbose" => @verbose,
        "return_output" => @return_output,
        "initialize_retrieve" => @initialize_retrieve
      }.delete_if{|k,v| v.nil?}
    end

    def verbose=(verbose)
      satisfy_class?(verbose, "verbose", [TrueClass, FalseClass])
    end

    def return_output=(return_output)
      satisfy_class?(return_output, "return_output", [TrueClass, FalseClass])
    end

    def initialize_retrieve=(initialize_retrieve)
      satisfy_class?(initialize_retrieve, "initialize_retrieve", [TrueClass, FalseClass])
    end

    def request(action:, url:, body: {}, headers: {}, query: {}, key: nil, return_direct_result: false, skip_to_json: false)
      send_url = "#{@base_uri}/#{url}"
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
      result = response.parsed_response
      puts result if @verbose
      if !result.is_a?(Hash) && !result.nil?
        raise Arango::Error message: "ArangoRB didn't return a valid hash", data: result
      elsif result.is_a?(Hash) && result["error"]
        raise Arango::Error message: result["errorMessage"], code: result["code"]
      end
      return result if return_direct_result || @return_output
      return true if action == "DELETE"
      return key.nil? ? result.delete_if{|k,v| k == "error" || k == "code"} : result[key]
    end

  #  == DATABASE ==

    def [](database)
      satisfy_class?(database, "database")
      Arango::Database.new(database: database, client: self)
    end
    alias database []

    def databases(user: nil)
      satisfy_class?(user, "user", [NilClass, String, Arango::User])
      if user.nil?
        result = request(action: "GET", url: "/_api/database")
      else
        user = user.name if user.is_a?(Arango::User)
        result = request(action: "GET", url: "/_api/database/#{user}")
      end
      return result if return_directly?(result)
      result["result"].map do |db|
        Arango::Database.new(database: db, client: self)
      end
    end

  # == ASYNC ==

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


end
