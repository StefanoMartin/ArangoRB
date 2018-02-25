# === USER ===

module Arango
  class User
    def initialize(client:, password: "", user:, extra: {}, active: nil)
      satisfy_class?(client, [Arango::Client])
      @password = password
      @user = user
      @extra = extra
      @active = active
      @client = client
    end

    attr_accessor :user, :extra, :active
    attr_reader :client
    attr_writer :password
    alias :name :user

    def client=(client)
      satisfy_class?(client, [Arango::Client])
      @client = client
    end

    def to_h(level=0)
      hash = {
        "user" => @user,
        "extra" => @extra,
        "active" => @active
      }.delete_if{|k,v| v.nil?}
      hash["client"] = level > 0 ? @client.to_h(level-1) : @client.base_uri

  # == PRIVATE ==

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @user = result["user"]
      @extra = result["extra"]
      @active = result["active"]
    end

  # == USER ACTION ==

    def create
      body = {
        "user"   => @user,
        "passwd" => @password,
        "extra"  => @extra,
        "active" => @active
      }
      result = @client.request(action: "POST", url: "_api/user", body: body)
      return_element(result)
    end

    def retrieve
      result = @client.request(action: "GET", url: "_api/user/#{@user}",
        body: body)
      return_element(result)
    end

    def replace(password: @password, active: @active, extra: @extra)
      body = {
        "passwd" => password,
        "active" => active,
        "extra"  => extra
      }
      result = @client.request(action: "PUT", url: "_api/user/#{@user}",  body: body)
      @password = password
      return_element(result)
    end

    def update(password: @password, active: nil, extra: nil)
      body = {
        "passwd" => password,
        "active" => active,
        "extra" => extra
      }
      result = @client.request(action: "PATCH", url: "_api/user/#{@user}",  body: body)
      @password = password
      return_element(result)
    end

    def destroy
      result = @client.request(action: "DELETE", url: "_api/user/#{@user}")
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
      result = @client.request(action: "POST", url: "_api/user/#{@user}/database/#{database}",
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
      result = @client.request(action: "POST", url: "_api/user/#{@user}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result["#{database}/#{collection}"]
    end

    def clear_database_access(database:)
      satisfy_class?(database, [Arango::Database, String])
      database = database.name if database.is_a?(Arango::Database)
      result = @client.request(action: "DELETE", url: "_api/user/#{@user}/database/#{database}")
      return return_directly?(result) ? result : true
    end

    def clear_collection_access(grant:, database:, collection:)
      satisfy_category?(grant, ["rw", "ro", "none"])
      satisfy_class?(database, [Arango::Database, String])
      satisfy_class?(collection, [Arango::Collection, String])
      database = database.name     if database.is_a?(Arango::Database)
      collection = collection.name if collection.is_a?(Arango::Collection)
      result = @client.request(action: "DELETE", url: "_api/user/#{@user}/database/#{database}/#{collection}")
      return return_directly?(result) ? result : true
    end

    def list_access(full: nil)
      query = {"full" => full}
      result = @client.request(action: "GET", url: "_api/user/#{@user}/database", query: query)
      return return_directly?(result) ? result : result["result"]
    end

    def database_access(database:)
      satisfy_class?(database, [Arango::Database, String])
      database = database.name if database.is_a?(Arango::Database)
      result = @client.request(action: "GET", url: "_api/user/#{@user}/database/#{database}")
      return return_directly?(result) ? result : result["result"]
    end

    def collection_access(database:, collection:)
    satisfy_class?(database, [Arango::Database, String])
    satisfy_class?(collection, [Arango::Collection, String])
    database = database.name     if database.is_a?(Arango::Database)
    collection = collection.name if collection.is_a?(Arango::Collection)
      result = @client.request(action: "GET", url: "_api/user/#{@user}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result["result"]
    end
  end
end
