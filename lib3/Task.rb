# === TASK ===

module Arango
  class Task
    def initialize(id: nil, name: nil, type: nil, period: nil, command: nil, params: {}, created: nil, database:, body: {})
      satisfy_class?(database, "database", [Arango::Database])
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
      @database = database
      @client = @database.client
    end

    attr_reader :id, :name, :type, :period, :created, :command, :params, :idCache, :offset, :client, :database

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

    def return_task(result)
      return result if @client.async != false
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end

# == RETRIEVE

    def retrieve
      result = @database.request(action: "GET", url: "/_api/tasks/#{@id}")
      return return_task(result)
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
      return return_task(result)
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
      return return_task(result)
    end

    def destroy
      result = @database.request(action: "DELETE", url: "/_api/task/#{@id}")
      return return_directly?(result) ? result : true
    end
  end
end
