# === TASK ===

module Arango
  class Task
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Server_Return

    def initialize(id: nil, name: nil, type: nil, period: nil, command: nil,
      params: {}, created: nil, server:, body: {})
      assign_server(server)
      body2 = {
        "id": id,
        "name": name,
        "type": type,
        "period": period,
        "command": command,
        "params": params,
        "created": created
      }
      body.merge!(body2)
      assign_attributes(body)
    end

 # === DEFINE ===

    attr_reader :server, :body
    attr_accessor :id, :name, :type, :period, :created,
      :command, :params, :offset

    def body=(result)
      @body    = result
      @id      = result[:id]      || @id
      @name    = result[:name]    || @name
      @type    = result[:type]    || @type
      @period  = result[:period]  || @period
      @command = result[:command] || @command
      @params  = result[:params]  || @params
      @offset  = result[:offset]  || @offset
      @created = result[:created] || @created
    end
    alias assign_attributes body=

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "id": @id,
        "name": @name,
        "type": @type,
        "period": @period,
        "command": @command,
        "params": @params,
        "created": @created
      }
      hash.delete_if{|k,v| v.nil?}
      hash[:server] = level > 0 ? @server.to_h(level-1) : @server.base_uri
      hash
    end

# == RETRIEVE

    def retrieve
      result = @database.request("GET", "/_api/tasks/#{@id}")
      return return_element(result)
    end

    def create(command: @command, period: @period, offset: @offset, params: @params)
      body = {
        "name": @name,
        "command": command,
        "period": period,
        "offset": offset,
        "params": params
      }
      result = @database.request("POST", "/_api/tasks", body: body)
      return return_element(result)
    end

    def update(command: @command, period: @period, offset: @offset,
      params: @params)
      body = {
        "name": @name,
        "command": command,
        "period": period,
        "offset": offset,
        "params": params
      }
      result = @database.request("PUT", "/_api/task/#{@id}", body: body)
      return return_element(result)
    end

    def destroy
      result = @database.request("DELETE", "/_api/task/#{@id}")
      return return_directly?(result) ? result : true
    end
  end
end
