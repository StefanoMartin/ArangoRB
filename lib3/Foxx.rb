# === FOXX ===

module Arango
  class Foxx
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(database:, body: {}, mount:, development: nil, legacy: nil, provides: nil, name: nil, version: nil, type: "application/json", setup: nil, teardown: nil)
      assign_database(database)
      assign_attributes(body)
      assign_type(type)
      @mount       ||= mount
      @development ||= development
      @setup       ||= setup
      @legacy      ||= legacy
      @provides    ||= provides
      @name        ||= name
      @version     ||= version
      @teardown    ||= teardown
    end

# === DEFINE ===

    attr_reader :database, :server, :type, :body
    attr_accessor :name, :development, :legacy, :provides,
      :version, :mount, :setup, :teardown

    def body=(result)
      if result.is_a?(Hash)
        @body        = result
        @name        = result[:name]        || @name
        @version     = result[:version]     || @version
        @mount       = result[:mount]       || @mount
        @development = result[:development] || @development
        @legacy      = result[:legacy]      || @legacy
        @provides    = result[:provides]    || @provides
      end
    end
    alias assign_attributes body=

    def type=(type)
      satisfy_category?(type, ["application/zip", "zip", "application/javascript", "javascript", "application/json", "json", "multipart/form-data", "data"], "type")
      type = "application/#{type}" if ["zip", "javascript", "json"].include?(type)
      type = "multipart/form-data" if type == "data"
      @type = type
    end
    alias assign_type type=

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "name": @name,
        "version": @version,
        "mount": @mount,
        "development": @development,
        "legacy": @legacy,
        "provides": @provides,
        "type": @type,
        "teardown": @teardown
      }.compact
      hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

    def return_foxx(result, val=nil)
      return result if @server.async != false
      case val
      when :configuration
        @configuration = result
      when :dependencies
        @dependencies = result
      else
        assign_attributes(result)
      end
      return return_directly?(result) ? result : self
    end
    private :return_foxx

  # === ACTIONS ===

    def retrieve
      query = {"mount": @mount}
      result = @database.request("GET", url: "_api/foxx/service")
      return_foxx(result)
    end

    def create(body: @body, type: @type, development: @development,
      setup: @setup, legacy: @legacy)
      headers = {"Accept": type}
      skip_to_json = type != "application/json"
      query = {
        "mount":        @mount,
        "setup":        setup,
        "development ": development ,
        "legacy":       legacy
      }
      result = @database.request("POST",
        url: "_api/foxx", body: body, headers: headers,
        skip_to_json: skip_to_json, query: query)
      return_foxx(result)
    end

    def destroy(teardown: @teardown)
      query = {
        "mount":    @mount,
        "teardown": teardown
      }
      result = @database.request("DELETE", "_api/foxx/service", query: query)
      return_foxx(result)
    end

    def replace(body: @body, type: @type, teardown: @teardown, setup: @setup,
      legacy: @legacy)
      headers = {"Accept": type}
      skip_to_json = type != "application/json"
      query = {
        "mount": @mount,
        "setup": setup,
        "development ": development,
        "legacy": legacy
      }
      result = @database.request("PUT", "_api/foxx/service", body: body,
        headers: headers, skip_to_json: skip_to_json, query: query)
      return_foxx(result)
    end

    def update(body: @body, type: @type, teardown: @teardown,
      setup: @setup, legacy: @legacy)
      assign_type(type)
      headers = {"Accept": type}
      skip_to_json = @type != "application/json"
      query = {
        "mount":        @mount,
        "setup":        setup,
        "development ": development,
        "legacy":       legacy
      }
      result = @database.request("PATCH", "_api/foxx/service", body: body,
        headers: headers, skip_to_json: skip_to_json, query: query)
      return_foxx(result)
    end

  # === CONFIGURATION ===

    def retrieveConfiguration
      query = {"mount": @mount}
      result = @database.request("GET", "_api/foxx/configuration", query: query)
      return_foxx(result, :configuration)
    end

    def updateConfiguration(body:)
      query = {"mount": @mount}
      result = @database.request("PATCH", "_api/foxx/configuration", query: query, body: body)
      return_foxx(result, :configuration)
    end

    def replaceConfiguration(body:)
      query = {"mount": @mount}
      result = @database.request("PUT", "_api/foxx/configuration", query: query, body: body)
      return_foxx(result, :configuration)
    end

    # === DEPENDENCY ===

    def retrieveDependencies
      query = {"mount": @mount}
      result = @database.request("GET", "_api/foxx/dependencies", query: query)
      return_foxx(result, :dependencies)
    end

    def updateDependencies(body:)
      query = {"mount": @mount}
      result = @database.request("PATCH", "_api/foxx/dependencies", query: query, body: body)
      return_foxx(result, :dependencies)
    end

    def replaceDependencies(body:)
      query = {"mount": @mount}
      result = @database.request("PUT", "_api/foxx/dependencies", query: query, body: body)
      return_foxx(result, :dependencies)
    end

    # === MISCELLANEOUS

    def scripts
      query = {"mount": @mount}
      @database.request("GET", "_api/foxx/scripts", query: query)
    end

    def run_script(name:, body: {})
      query = {"mount": @mount}
      @database.request("POST", "_api/foxx/scripts/#{name}", query: query, body: body)
    end

    def tests(reporter: nil, idiomatic: nil)
      satisfy_category?(reporter, [nil, "default", "suite", "stream", "xunit", "tap"])
      headers = {}
      headers[:"Content-Type"] = case reporter
      when "stream"
        "application/x-ldjson"
      when "tap"
        "text/plain, text/*"
      when "xunit"
        "application/xml, text/xml"
      else
        nil
      end
      query = {"mount": @mount}
      @database.request("GET", "_api/foxx/scripts", query: query, headers: headers)
    end

    def enableDevelopment
      query = {"mount": @mount}
      @database.request("POST", "_api/foxx/development", query: query)
    end

    def disableDevelopment
      query = {"mount": @mount}
      @database.request("DELETE", "_api/foxx/development", query: query)
    end

    def readme
      query = {"mount": @mount}
      @database.request("GET", "_api/foxx/readme", query: query)
    end

    def swagger
      query = {"mount": @mount}
      @database.request("GET", "_api/foxx/swagger", query: query)
    end

    def download(path:, warning: @server.warning)
      query = {"mount": @mount}
      @server.download("POST", "/_db/#{@database.name}/_api/foxx/download",
        path: path, query: query)
      puts "File saved in #{path}" if warning
    end

    def commit(body:, replace: nil)
      query = {"replace": replace}
      @database.request("POST", "_api/foxx/commit", body: body, query: query)
    end
  end
end
