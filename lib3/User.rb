# === USER ===

module Arango
  class User
    include Arango::Helper_Error
    include Arango::Helper_Return

    def initialize(client:, password: "", name:, extra: {}, active: nil)
      satisfy_class?(client, [Arango::Client])
      @password = password
      @name     = name
      @extra    = extra
      @active   = active
      @client   = client
    end

# === DEFINE ===

    attr_accessor :name, :extra, :active
    attr_reader :client, :body
    attr_writer :password
    alias :user :name

    def client=(client)
      satisfy_class?(client, [Arango::Client])
      @client = client
    end

    def body=(result)
      @body   = result.delete_if{|k,v| v.nil?}
      @name   = result["user"]
      @extra  = result["extra"]
      @active = result["active"]
    end
    alias assign_attributes body=

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "user" => @name,
        "extra" => @extra,
        "active" => @active
      }.delete_if{|k,v| v.nil?}
      hash["client"] = level > 0 ? @client.to_h(level-1) : @client.base_uri

  # == USER ACTION ==

    def create(password: @password, active: @active, extra: @extra)
      body = {
        "user"   => @name,
        "passwd" => password,
        "extra"  => extra,
        "active" => active
      }
      result = @client.request(action: "POST", url: "_api/user", body: body)
      return_element(result)
    end

    def retrieve
      result = @client.request(action: "GET", url: "_api/user/#{@name}",
        body: body)
      return_element(result)
    end

    def replace(password: @password, active: @active, extra: @extra)
      body = {
        "passwd" => password,
        "active" => active,
        "extra"  => extra
      }
      result = @client.request(action: "PUT", url: "_api/user/#{@name}",  body: body)
      @password = password
      return_element(result)
    end

    def update(password: @password, active: @active, extra: @extra)
      body = {
        "passwd" => password,
        "active" => active,
        "extra" => extra
      }
      result = @client.request(action: "PATCH", url: "_api/user/#{@name}",
        body: body)
      @password = password
      return_element(result)
    end

    def destroy
      result = @client.request(action: "DELETE", url: "_api/user/#{@name}")
      return return_directly?(result) ? result : true
    end

  # == ACCESS ==

    def add_database_access(grant:, database:)
      satisfy_category?(grant, ["rw", "ro", "none"])
      satisfy_class?(database, [Arango::Database, String])
      if database.is_a?(Arango::Database)
        database = database.name
      end
      body = {"grant" => grant}
      result = @client.request(action: "POST", url: "_api/user/#{@name}/database/#{database}",
        body: body)
      return return_directly?(result) ? result : result[database]
    end

    def add_collection_access(grant:, database:, collection:)
      satisfy_category?(grant, ["rw", "ro", "none"])
      satisfy_class?(database, [Arango::Database, String])
      satisfy_class?(collection, [Arango::Collection, String])
      database = database.name     if database.is_a?(Arango::Database)
      collection = collection.name if collection.is_a?(Arango::Collection)
      body = {"grant" => grant}
      result = @client.request(action: "POST", url: "_api/user/#{@name}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result["#{database}/#{collection}"]
    end

    def clear_database_access(database:)
      satisfy_class?(database, [Arango::Database, String])
      database = database.name if database.is_a?(Arango::Database)
      result = @client.request(action: "DELETE", url: "_api/user/#{@name}/database/#{database}")
      return return_directly?(result) ? result : true
    end

    def clear_collection_access(grant:, database:, collection:)
      satisfy_category?(grant, ["rw", "ro", "none"])
      satisfy_class?(database, [Arango::Database, String])
      satisfy_class?(collection, [Arango::Collection, String])
      database = database.name     if database.is_a?(Arango::Database)
      collection = collection.name if collection.is_a?(Arango::Collection)
      result = @client.request(action: "DELETE", url: "_api/user/#{@name}/database/#{database}/#{collection}")
      return return_directly?(result) ? result : true
    end

    def list_access(full: nil)
      query = {"full" => full}
      result = @client.request(action: "GET", url: "_api/user/#{@name}/database", query: query)
      return return_directly?(result) ? result : result["result"]
    end

    def database_access(database:)
      satisfy_class?(database, [Arango::Database, String])
      database = database.name if database.is_a?(Arango::Database)
      result = @client.request(action: "GET", url: "_api/user/#{@name}/database/#{database}")
      return return_directly?(result) ? result : result["result"]
    end

    def collection_access(database:, collection:)
    satisfy_class?(database, [Arango::Database, String])
    satisfy_class?(collection, [Arango::Collection, String])
    database = database.name     if database.is_a?(Arango::Database)
    collection = collection.name if collection.is_a?(Arango::Collection)
      result = @client.request(action: "GET", url: "_api/user/#{@name}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result["result"]
    end
  end
end
