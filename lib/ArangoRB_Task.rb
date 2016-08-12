# === AQL ===

class ArangoTask < ArangoServer
  def initialize(database: @@database, id: nil, name: nil, type: nil, period: nil, command: nil, params: {}, created: nil) # TESTED
    if database.is_a?(String)
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be a String or an ArangoDatabase instance, not a #{database.class}"
    end
    @id = id
    @name = name
    @type = type
    @period = period
    @command = command
    @params = params
    @created = created
  end

  attr_reader :id, :name, :type, :period, :created, :command, :params

  def database
    ArangoDatabase.new(database: @database)
  end

  def retrieve # TESTED
    result = self.class.get("/_db/#{@database}/_api/tasks/#{@id}")
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

  def self.tasks # TESTED
    result = get("/_db/#{@@database}/_api/tasks", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : (result.is_a?(Hash) && result["error"]) ? result["errorMessage"] : result.map{|x| ArangoTask.new(id: x["id"], name: x["name"], type: x["type"], period: x["period"], created: x["created"], command: x["command"], database: x["database"])}
  end

  def create offset: nil # TESTED
    body = {
      "name" => @name,
      "command" => @command,
      "period" => @period,
      "offset" => offset,
      "params" => @params
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    if @id.nil?
      result = self.class.post("/_db/#{@database}/_api/tasks", request)
    else
      result = self.class.put("/_db/#{@database}/_api/tasks/#{@id}", request)
    end
    return result.headers["x-arango-async-id"] if @@async == "store"
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
      return result["errorMessage"] if result.is_a?(Hash) && result["error"]
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

  def destroy # TESTED
    result = self.class.delete("/_db/#{@database}/_api/tasks/#{@id}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : (result.is_a?(Hash) && result["error"]) ? result["errorMessage"] : true
  end
end
