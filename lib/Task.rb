# === TASK ===

module Arango
  class Task
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      database = hash[:database]
      if database.is_a?(Arango::Database) && database.server.active_cache && !hash[:id].nil?
        cache_name = "#{database.name}/#{hash[:id]}"
        cached = database.server.cache.cache.dig(:task, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = hash[:body] || {}
          [:name, :type, :period, :command, :params, :created].each{|k| body[k] ||= hash[k]}
          cached.assign_attributes(body)
        end
      end
      super
    end

    def initialize(id: nil, name: nil, type: nil, period: nil, command: nil,
      params: nil, created: nil, body: {}, database:, cache_name: nil)
      assign_database(database)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:task, cache_name, self)
      end
      [:id, :name, :type, :period, :command, :params, :created].each do |k|
        body[k] ||= binding.local_variable_get(k)
      end
      assign_attributes(body)
    end

 # === DEFINE ===

    attr_reader :server, :body, :database, :cache_name
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
      if @server.active_cache && @cache_name.nil?
        @cache_name = "#{@database.name}/#{@id}"
        @server.cache.save(:task, @cache_name, self)
      end
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
        "created": @created,
        "cache_name": @cache_name
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
