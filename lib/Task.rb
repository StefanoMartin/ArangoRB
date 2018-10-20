# === TASK ===

module Arango
  class Task
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(id: nil, name: nil, type: nil, period: nil, command: nil,
      params: nil, created: nil, body: {}, database:)
      assign_database(database)
      body2 = {
        "id": id,
        "name": name,
        "type": type,
        "period": period,
        "command": command,
        "params": params,
        "created": created
      }.delete_if{|k,v| v.nil?}
      body.merge!(body2)
      assign_attributes(body)
    end

 # === DEFINE ===

    attr_reader :server, :body, :database
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
      hash[:database] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

# == RETRIEVE

    def retrieve
      result = @database.request("GET", "_api/tasks/#{@id}")
      return return_element(result)
    end

    def create(command: @command, period: @period, offset: @offset, params: @params)
      body = {
        "id": @id,
        "name": @name,
        "command": command,
        "period": period,
        "offset": offset,
        "params": params,
        "database": @database.name
      }
      result = @database.request("POST", "_api/tasks", body: body)
      return return_element(result)
    end

    def update(command: @command, period: @period, offset: @offset,
      params: @params)
      body = {
        "id": @id,
        "name": @name,
        "command": command,
        "period": period,
        "offset": offset,
        "params": params
      }
      result = @database.request("PUT", "_api/tasks/#{@id}", body: body)
      return return_element(result)
    end

    def destroy
      result = @server.request("DELETE", "_api/tasks/#{@id}")
      return return_directly?(result) ? result : true
    end
  end
end
