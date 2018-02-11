# === USER ===

module Arango
  class User
    def initialize(client:, password: "", user:, extra: {},
      active: nil)
      satisfy_class?(passwd, "passwd")
      satisfy_class?(user, "user")
      satisfy_class?(client, "client", [Arango::Client])
      satisfy_class?(body, "body", [Hash])
      satisfy_category?(type, , "type", ["Document", "Edge"])
      @password = passwd
      @user = user
      @extra = extra
      @active = active
      @client = client
    end

    attr_reader :user, :client, :extra

  # == PRIVATE ==

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @user = result["user"]
      @extra = result["extra"]
      @active = result["active"]
    end

    def return_user(result)
      return result if @client.async != false
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end

  # == USER ACTION ==

    def create(user: @user, passwd: @password, extra: @extra,
      active: @active)
      body = {
        "user" => user,
        "passwd" => passwd,
        "extra" => extra,
        "active" => active
      }
      @password = passwd
      result = @client.request(action: "POST", url: "_api/user",
        body: body)
      return_user(result)
    end

    def retrieve
      result = @client.request(action: "GET", url: "_api/user/#{@suer}", body: body)
      return_user(result)
    end

    def replace(password: @password, active: nil, extra: nil)
      body = {
        "passwd" => password,
        "active" => active,
        "extra" => extra
      }
      @password = password
      request = @body.merge(nody)
      result = @client.request(action: "PUT", url: "_api/user/#{@user}",  body: body)
      return_user(result)
    end

    def update(password: @password, active: nil, extra: nil)
      body = {
        "passwd" => password,
        "active" => active,
        "extra" => extra
      }
      @password = password
      request = @body.merge(body)
      result = @client.request(action: "PATCH", url: "_api/user/#{@user}",  body: body)
      return_user(result)
    end

    def destroy # TESTED
      result = @client.request(action: "DELETE", url: "_api/user/#{@user}")
      return return_directly?(result) ? result : true
    end

  # == ACCESS ==

    def add_database_access(grant:, database:)
      satisfy_category?(grant, ["rw", "ro", "none"], "grant")
      satisfy_class?(database, "database", [Arango::Database, String])
      if database.is_a?(Arango::Database)
        database = database.name
      end
      body = {"grant" => grant}
      result = @client.request(action: "POST", url: "_api/user/#{@user}/database/#{database}",
        body: body)
      return return_directly?(result) ? result : result[database]
    end

    def add_collection_access(grant:, database:, collection:)
      satisfy_category?(grant, ["rw", "ro", "none"], "grant")
      satisfy_class?(database, "database", [Arango::Database, String])
      satisfy_class?(collection, "collection", [Arango::Collection, String])
      if database.is_a?(Arango::Database)
        database = database.name
      end
      if collection.is_a?(Arango::Collection)
        collection = collection.name
      end
      body = {"grant" => grant}
      result = @client.request(action: "POST", url: "_api/user/#{@user}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result["#{database}/#{collection}"]
    end

    def clear_database_access(database:)
      satisfy_class?(database, "database", [Arango::Database, String])
      if database.is_a?(Arango::Database)
        database = database.name
      end
      result = @client.request(action: "DELETE", url: "_api/user/#{@user}/database/#{database}")
      return return_directly?(result) ? result : true
    end

    def clear_collection_access(grant:, database:, collection:)
      satisfy_category?(grant, ["rw", "ro", "none"], "grant")
      satisfy_class?(database, "database", [Arango::Database, String])
      satisfy_class?(collection, "collection", [Arango::Collection, String])
      if database.is_a?(Arango::Database)
        database = database.name
      end
      if collection.is_a?(Arango::Collection)
        collection = collection.name
      end
      result = @client.request(action: "DELETE", url: "_api/user/#{@user}/database/#{database}/#{collection}")
      return return_directly?(result) ? result : true
    end

    def list_access(full: nil)
      query = {"full" => full}
      result = @client.request(action: "GET", url: "_api/user/#{@user}/database", query: query)
      return return_directly?(result) ? result : result["result"]
    end

    def database_access(database:)
      satisfy_class?(database, "database", [Arango::Database, String])
      if database.is_a?(Arango::Database)
        database = database.name
      end
      result = @client.request(action: "GET", url: "_api/user/#{@user}/database/#{database}")
      return return_directly?(result) ? result : result["result"]
    end

    def collection_access(database:, collection:)
      satisfy_class?(database, "database", [Arango::Database, String])
      satisfy_class?(collection, "collection", [Arango::Collection, String])
      if database.is_a?(Arango::Database)
        database = database.name
      end
      if collection.is_a?(Arango::Collection)
        collection = collection.name
      end
      result = @client.request(action: "GET", url: "_api/user/#{@user}/database/#{database}/#{collection}",
        body: body)
      return return_directly?(result) ? result : result["result"]
    end
  end
end
