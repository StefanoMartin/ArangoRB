# === USER ===

module Arango
  class User
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Server_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      database = hash[:database]
      if database.is_a?(Arango::Database) && database.server.active_cache
        cache_name = hash[:name]
        cached = database.server.cache.cache.dig(:user, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = {}
          [:password, :extra, :active].each{|k| body[k] ||= hash[k]}
          cached.assign_attributes(body)
          return cached
        end
      end
      super
    end

    def initialize(server:, password: "", name:, extra: {}, active: nil, cache_name: nil)
      assign_server(server)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:user, cache_name, self)
      end
      @password = password
      @name     = name
      @extra    = extra
      @active   = active
    end

# === DEFINE ===

    attr_accessor :name, :extra, :active
    attr_reader :server, :body, :cache_name
    attr_writer :password
    alias user name
    alias user= name=

    def body=(result)
      @body   = result
      @password = result[:password] || @password
      @name   = result[:user]   || @name
      @extra  = result[:extra]  || @extra
      @active = result[:active].nil? ? @active : result[:active]
      if @server.active_cache && @cache_name.nil?
        @cache_name = @name
        @server.cache.save(:user, @cache_name, self)
      end
    end
    alias assign_attributes body=

# === TO HASH ===

    def to_h
      {
        "user": @name,
        "extra": @extra,
        "active": @active,
        "cache_name": @cache_name,
        "server": @server.base_uri
      }.delete_if{|k,v| v.nil?}
    end

    def [](database)
      if self.databases[database.to_sym] == "rw"
        Arango::Database.new name: database, server: @server
      else
        "This User does not have access to Database #{database}."
      end
    end
    alias database []

  # == USER ACTION ==

    def create(password: @password, active: @active, extra: @extra)
      body = {
        "user": @name,
        "passwd": password,
        "extra": extra,
        "active": active
      }
      result = @server.request("POST", "_api/user", body: body)
      return_element(result)
    end

    def retrieve
      result = @server.request("GET", "_api/user/#{@name}", body: body)
      return_element(result)
    end

    def replace(password: @password, active: @active, extra: @extra)
      body = {
        "passwd": password,
        "active": active,
        "extra": extra
      }
      result = @server.request("PUT", "_api/user/#{@name}", body: body)
      @password = password
      return_element(result)
    end

    def update(password: @password, active: @active, extra: @extra)
      body = {
        "passwd": password,
        "active": active,
        "extra": extra
      }
      result = @server.request("PATCH", "_api/user/#{@name}", body: body)
      @password = password
      return_element(result)
    end

    def destroy
      result = @server.request("DELETE", "_api/user/#{@name}")
      return return_directly?(result) ? result : true
    end

  # == ACCESS ==

    def addDatabaseAccess(grant:, database:)
      satisfy_category?(grant, ["rw", "ro", "none"])
      satisfy_class?(database, [Arango::Database, String])
      database = database.name if database.is_a?(Arango::Database)
      body = {"grant": grant}
      result = @server.request("PUT", "_api/user/#{@name}/database/#{database}",
        body: body)
      return return_directly?(result) ? result : result[database.to_sym]
    end

    def grant(database:)
      addDatabaseAccess(grant: "rw", database: database)
    end

    def addCollectionAccess(grant:, database:, collection:)
      satisfy_category?(grant, ["rw", "ro", "none"])
      satisfy_class?(database, [Arango::Database, String])
      satisfy_class?(collection, [Arango::Collection, String])
      database = database.name     if database.is_a?(Arango::Database)
      collection = collection.name if collection.is_a?(Arango::Collection)
      body = {"grant": grant}
      result = @server.request("PUT", "_api/user/#{@name}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result[:"#{database}/#{collection}"]
    end

    def revokeDatabaseAccess(database:)
      satisfy_class?(database, [Arango::Database, String])
      database = database.name if database.is_a?(Arango::Database)
      result = @server.request("DELETE", "_api/user/#{@name}/database/#{database}")
      return return_directly?(result) ? result : true
    end
    alias revoke revokeDatabaseAccess

    def revokeCollectionAccess(database:, collection:)
      satisfy_class?(database, [Arango::Database, String])
      satisfy_class?(collection, [Arango::Collection, String])
      database = database.name     if database.is_a?(Arango::Database)
      collection = collection.name if collection.is_a?(Arango::Collection)
      result = @server.request("DELETE", "_api/user/#{@name}/database/#{database}/#{collection}")
      return return_directly?(result) ? result : true
    end

    def listAccess(full: nil)
      query = {"full": full}
      result = @server.request("GET", "_api/user/#{@name}/database", query: query)
      return return_directly?(result) ? result : result[:result]
    end
    alias databases listAccess

    def databaseAccess(database:)
      satisfy_class?(database, [Arango::Database, String])
      database = database.name if database.is_a?(Arango::Database)
      result = @server.request("GET", "_api/user/#{@name}/database/#{database}")
      return return_directly?(result) ? result : result[:result]
    end

    def collectionAccess(database:, collection:)
      satisfy_class?(database, [Arango::Database, String])
      satisfy_class?(collection, [Arango::Collection, String])
      database = database.name     if database.is_a?(Arango::Database)
      collection = collection.name if collection.is_a?(Arango::Collection)
      result = @server.request("GET", "_api/user/#{@name}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result[:result]
    end
  end
end
