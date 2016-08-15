# === USER ===

class ArangoUser < ArangoServer
  def initialize(user: @@user, password: nil, active: nil, extra: nil) # TESTED
    @password = password
    @user = user
    @active = active
    @extra = extra
  end

  attr_reader :user, :active, :extra
  alias name user

  def [](database)
    if self.databases[database] == "rw"
      ArangoDatabase.new database: database
    else
      "This User does not have access to Database #{database}."
    end
  end
  alias database []

  def create # TESTED
    body = {
      "user" => @user,
      "passwd" => @password,
      "active" => @active,
      "extra" => @extra
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_api/user", request)
    return_result result: result
  end

  def retrieve # TESTED
    result = self.class.get("/_api/user/#{@user}", @@request)
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
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @password = password
        @active = active.nil? || active
        @extra = extra
      end
      result
    else
      return result["errorMessage"] if result["error"]
      @password = password
      @active = active.nil? || active
      @extra = extra
      self
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
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @password = password
        @active = active.nil? || active
        @extra = extra
      end
      result
    else
      return result["errorMessage"] if result["error"]
      @password = password
      @active = active.nil? || active
      @extra = extra
      self
    end
  end

  def destroy # TESTED
    result = self.class.delete("/_api/user/#{@user}", @@request)
    return_result result: result, caseTrue: true
  end

  def return_result(result:, caseTrue: false, key: nil)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    if @@verbose || !result.is_a?(Hash)
      unless result["error"]
        @active = result["active"]
        @extra = result["extra"]
      end
      result
    else
      return result["errorMessage"] if result["error"]
      @active = result["active"]
      @extra = result["extra"]
      return true if caseTrue
      key.nil? ? self : result[key]
    end
  end
end
