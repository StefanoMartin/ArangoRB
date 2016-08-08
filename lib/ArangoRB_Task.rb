# === AQL ===

class ArangoTask < ArangoServer
  def initialize(id:, name: nil, type: nil, period: nil, created: nil, command: nil, database: nil, params: {})
    @id = id
    @name = name
    @type = type
    @period = period
    @created = created
    @command = command
    @database = database
    @params = params
  end

  attr_reader :id, :name, :type, :period, :created, :command, :database

  def retrieve
    result = self.class.get("/_api/tasks/#{@id}")
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        unless result.is_a?(Hash) && result["error"]
          @name = result["name"]
          @type = result["type"]
          @period = result["period"]
          @created = result["created"]
          @command = result["command"]
          @database = result["database"]
        end
        result
      else
        if result.is_a?(Hash) && result["error"]
          result["errorMessage"]
        else
          @name = result["name"]
          @type = result["type"]
          @period = result["period"]
          @created = result["created"]
          @command = result["command"]
          @database = result["database"]
          self
        end
      end
    end
  end

  def create params: nil, offset: nil
    body = {
      "name" => @name,
      "command" => @command,
      "period" => @period,
      "offset" => offset,
      "param" => params
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    if @id.nil?
      result = self.class.post("/_api/tasks", request)
    else
      result = self.class.put("/_api/tasks/#{@id}", request)
    end
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        unless result.is_a?(Hash) && result["error"]
          @id = result["id"]
          @name = result["name"]
          @type = result["type"]
          @period = result["period"]
          @created = result["created"]
          @command = result["command"]
          @database = result["database"]
        end
        result
      else
        if result.is_a?(Hash) && result["error"]
          result["errorMessage"]
        else
          @id = result["id"]
          @name = result["name"]
          @type = result["type"]
          @period = result["period"]
          @created = result["created"]
          @command = result["command"]
          @database = result["database"]
          self
        end
      end
    end
  end

  def destroy
    result = self.class.delete("/_api/tasks/#{@id}", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result.is_a?(Hash) && result["error"]
          result["errorMessage"]
        else
          true
        end
      end
    end
  end
end
