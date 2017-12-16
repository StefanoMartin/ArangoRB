# === FOXX ===

module Arango
  class Foxx
    def initialize(database:, body: {}, mount:, development: nil, legacy: nil, provides: nil, name: nil, version: nil,
      type: "application/json")
      satisfy_class?(name, "name")
      satisfy_class?(database, "database", [Arango::Database])
      satisfy_class?(body, "body", [Hash])
      satisfy_category?(type, , "type", ["Document", "Edge"])
      @name = name
      @database = database
      @client = @database.client
      assign_attributes(body)
      @mount ||= mount
      @development ||= development
      @legacy ||= legacy
      @provides ||= provides
      @name ||= name
      @version ||= version
      @type ||= type
      ignore_exception(retrieve) if @client.initialize_retrieve
    end

    attr_reader :name, :database, :body, :development, :legacy,
      :provides, :name, :version, :client

    def assign_attributes(result)
      if result.is_a?(Hash)
        @body = result
        @name = result["name"]
        @version = result["version"]
        @mount = result["mount"]
        @development = result["development"]
        @legacy = result["legacy"]
        @provides = result["provides"]
      end
    end

    def return_foxx(result, val=nil)
      return result if @database.client.async != false
      if val == "configuration"
        @configuration = result
      elsif val == "dependencies"
        @dependencies = result
      else
        assign_attributes(result)
      end
      return return_directly?(result) ? result : self
    end

    def assign_type(type)
      satisfy_category?(type, ["application/zip", "zip", "application/javascript", "javascript", "application/json", "json", "multipart/form-data", "data"], "type")
      type = "application/#{type}" if ["zip", "javascript", "json"].include?(type)
      type = "multipart/form-data" if type == "data"
      return type
    end

  # === RETRIEVE ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/foxx/service")
      return_foxx(result)
    end

    def create(body: @body, type: @type, teardown: nil, setup: nil,
      legacy: @legacy)
      @type = assign_type(type)
      headers = {"Accept": @type}
      skip_to_json = @type != "application/json"
      query = {"mount": @mount, "setup": setup, "teardown": teardown,
        "legacy": legacy }
      result = @database.request(action: "POST", url: "_api/foxx",
        body: body, headers: headers, skip_to_json: skip_to_json,
        query: query)
      return_foxx(result)
    end

    def destroy(teardown: nil)
      query = {mount: mount, teardown: teardown}
      result = @database.request(action: "GET",
        url: "_api/foxx/service",  query: query)
      return_foxx(result)
    end

    def replace(body: @body, type: @type, teardown: nil, setup: nil, legacy: @legacy)
      @type = assign_type(type)
      headers = {"Accept": @type}
      skip_to_json = @type != "application/json"
      query = {"mount": @mount, "setup": setup, "teardown": teardown,
        "legacy": legacy }
      result = @database.request(action: "PUT",
        url: "_api/foxx/service", body: body, headers: headers,
        skip_to_json: skip_to_json, query: query)
      return_foxx(result)
    end

    def update(body: @body, type: @type, teardown: nil, setup: nil, legacy: @legacy)
      @type = assign_type(type)
      headers = {"Accept": @type}
      skip_to_json = @type != "application/json"
      query = {"mount": @mount, "setup": setup, "teardown": teardown,
        "legacy": legacy }
      result = @database.request(action: "PATCH",
        url: "_api/foxx/service", body: body, headers: headers,
        skip_to_json: skip_to_json, query: query)
      return_foxx(result)
    end

  # === CONFIGURATION ===

    def retrieveConfiguration
      query = {"mount": @mount}
      result = @database.request(action: "GET",
        url: "_api/foxx/configuration",  query: query)
      return_foxx(result, "configuration")
    end

    def updateConfiguration(body:)
      query = {"mount": @mount}
      result = @database.request(action: "PATCH",
        url: "_api/foxx/configuration",  query: query, body: body)
      return_foxx(result, "configuration")
    end

    def replaceConfiguration(body:)
      query = {"mount": @mount}
      result = @database.request(action: "PUT",
        url: "_api/foxx/configuration",  query: query, body: body)
      return_foxx(result, "configuration")
    end

    # === DEPENDENCY ===

    def retrieveDependencies
      query = {"mount": @mount}
      result = @database.request(action: "GET",
        url: "_api/foxx/dependencies",  query: query)
      return_foxx(result, "dependencies")
    end

    def updateDependencies(body:)
      query = {"mount": @mount}
      result = @database.request(action: "PATCH",
        url: "_api/foxx/dependencies",  query: query, body: body)
      return_foxx(result, "dependencies")
    end

    def replaceDependencies(body:)
      query = {"mount": @mount}
      result = @database.request(action: "PUT",
        url: "_api/foxx/dependencies",  query: query, body: body)
      return_foxx(result, "dependencies")
    end

    # === MISCELLANEOUS

    def scripts
      query = {"mount": @mount}
      @database.request(action: "GET",
        url: "_api/foxx/scripts",  query: query)
    end

    def run_script(name:, body: {})
      query = {"mount": @mount}
      @database.request(action: "POST",
        url: "_api/foxx/scripts/#{name}", query: query, body: body)
    end


    def tests(reporter: nil, idiomatic: nil)
      satisfy_category?(reporter, [nil, "default", "suite", "stream", "xunit", "tap"], "reporter")
      headers = {}
      if reporter == "stream"
        headers["Content-Type"] = "application/x-ldjson"
      elsif reporter == "tap"
        headers["Content-Type"] = "text/plain, text/*"
      elsif reporter == "xunit"
        headers["Content-Type"] = "application/xml, text/xml"
      end
      query = {"mount": @mount}
      @database.request(action: "GET",
        url: "_api/foxx/scripts",  query: query, headers: headers)
    end

    def enableDevelopment
      query = {"mount": @mount}
      @database.request(action: "POST", query: query,
        url: "_api/foxx/development")
    end

    def disableDevelopment
      query = {"mount": @mount}
      @database.request(action: "DELETE", query: query,
        url: "_api/foxx/development")
    end

    def readme
      query = {"mount": @mount}
      @database.request(action: "GET",
        url: "_api/foxx/readme",  query: query)
    end

    def swagger
      query = {"mount": @mount}
      @database.request(action: "GET",
        url: "_api/foxx/swagger",  query: query)
    end

    def download(path:, warning: true)
      query = {"mount": @mount}
      @client.download(action: "POST",
        url: "/_db/#{@database.name}/_api/foxx/download", path: path, query: query)
      puts "File saved in #{path}" if warning
    end

    def commit(body:, replace: nil)
      query = {"replace":replace}
      @database.request(action: "POST",
        url: "_api/foxx/commit", body: body query: query)
    end
  end
end
