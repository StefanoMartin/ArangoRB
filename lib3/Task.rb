# === TASK ===

module Arango
  class Task
    def initialize(id: nil, name: nil, type: nil, period: nil, command: nil, params: {}, created: nil, database:, body: {})
      satisfy_class?(database, [Arango::Database])
      @database = database
      @client = @database.client
      body2 = {
        "id" => id,
        "name" => name,
        "type" => type,
        "period" => period,
        "command" => command,
        "params" => params,
        "created" => created
      }
      body.merge!(body2)
      assign_attributes(body)
    end

    attr_reader :client, :database
    attr_accessor :id, :name, :type, :period, :created,
      :command, :params, :idCache, :offset

    def database=(database)
      satisfy_class?(database, [Arango::Database])
      @database = database
      @client = @database.client
    end

    def to_h(level=0)
      hash = {
        "id" => @id,
        "name" => @name,
        "type" => @type,
        "period" => @period,
        "command" => @command,
        "params" => @params,
        "created" => @created
      }.delete_if{|k,v| v.nil?}
      hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

  # == PRIVATE ==

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @id = result["id"]
      @name = result["name"]
      @type = result["type"]
      @period = result["period"]
      @command = result["command"]
      @params = result["params"]
      @offset = result["offset"]
      @created = result["created"]
    end

# == RETRIEVE

    def retrieve
      result = @database.request(action: "GET", url: "/_api/tasks/#{@id}")
      return return_element(result)
    end

    def create
      body = {
        "name" => @name,
        "command" => @command,
        "period" => @period,
        "offset" => @offset,
        "params" => @params
      }
      result = @database.request(action: "POST", url: "/_api/tasks")
      return return_element(result)
    end

    def update
      body = {
        "name" => @name,
        "command" => @command,
        "period" => @period,
        "offset" => @offset,
        "params" => @params
      }
      result = @database.request(action: "PUT", url: "/_api/task/#{@id}")
      return return_element(result)
    end

    def destroy
      result = @database.request(action: "DELETE", url: "/_api/task/#{@id}")
      return return_directly?(result) ? result : true
    end
  end
end
