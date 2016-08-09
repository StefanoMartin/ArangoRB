# === USER ===

class ArangoUser < ArangoServer
  def initialize(user: @@user, password: nil, active: nil, extra: nil) # TESTED
    @password = password
    @user = user
    @active = active
    @extra = extra
  end

  attr_reader :user, :active, :extra

  def create(active: nil, extra: nil) # TESTED
    body = {
      "user" => @user,
      "passwd" => @password,
      "active" => active,
      "extra" => extra
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_api/user", request)
    resultTemp = result.parsed_response
    if @@async != "store" && !resultTemp["error"]
      @active = resultTemp["active"]
      @extra = resultTemp["extra"]
    end
    return_result result: result
  end

  def retrieve # TESTED
    result = self.class.get("/_api/user/#{@user}", @@request)
    resultTemp = result.parsed_response
    if @@async != "store" && !resultTemp["error"]
      @active = resultTemp["active"]
      @extra = resultTemp["extra"]
    end
    return_result result: result
  end

  def grant(database: @@database) # TESTED
    database = database.database if database.is_a?(ArangoDatabase)
    body = { "grant" => "rw" }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_api/user/#{@user}/database/#{database}", request)
    return_result result: result, caseTrue: true
  end

  def revoke(database: @@database) # TESTED
    database = database.database if database.is_a?(ArangoDatabase)
    body = { "grant" => "none" }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_api/user/#{@user}/database/#{database}", request)
    return_result result: result, caseTrue: true
  end

  def databases # TESTED
    result = self.class.get("/_api/user/#{@user}/database/", @@request)
    return_result result: result, key: "result"
  end

  def replace(password:, active: nil, extra: nil) # TESTED
    body = {
      "passwd" => password,
      "active" => active,
      "extra" => extra
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_api/user/#{@user}", request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        unless result["error"]
          @password = password
          @active = active.nil? || active
          @extra = extra
        end
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          @password = password
          @active = active.nil? || active
          @extra = extra
          self
        end
      end
    end
  end

  def update(password: , active: nil, extra: nil) # TESTED
    body = {
      "passwd" => password,
      "active" => active,
      "extra" => extra
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.patch("/_api/user/#{@user}", request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        unless result["error"]
          @password = password
          @active = active.nil? || active
          @extra = extra
        end
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          @password = password
          @active = active.nil? || active
          @extra = extra
          self
        end
      end
    end
  end

  def destroy # TESTED
    result = self.class.delete("/_api/user/#{@user}", @@request)
    return_result result: result, caseTrue: true
  end

  def return_result(result:, caseTrue: false, key: nil)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose || !result.is_a?(Hash)
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          if caseTrue
            true
          elsif key.nil?
            self
          else
            result[key]
          end
        end
      end
    end
  end
end
