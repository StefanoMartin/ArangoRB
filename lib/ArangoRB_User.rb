# === USER ===

class ArangoUser < ArangoServer
  def initialize(user: @@user, password: nil, active: nil, extra: nil)
    @password = password
    @user = user
    @active = active
    @extra = extra
  end

  attr_reader :user

  def create(active: nil, extra: nil)
    body = {
      "user" => @user,
      "passwd" => @password,
      "active" => active,
      "extra" => extra
    }.delete_if{|k,v| v.nil?}.to_json
    new_DB = { :body => body }
    result = self.class.post("/_api/user", new_DB).parsed_response
    if @@verbose
      result
    else
      if result["error"]
        result["errorMessage"]
      else
        @active =  active.nil? || active
        @extra = extra
        self
      end
    end
  end

  def retrieve
    result = self.class.get("/_api/user/#{@user}").parsed_response
    if @@verbose
      result
    else
      if result["error"]
        result["errorMessage"]
      else
        result.delete("error")
        result.delete("code")
        result
      end
    end
  end

  def grant(database: @@database)
    database = database.database if database.is_a?(ArangoDatabase)
    body = { "grant" => "rw" }.to_json
    new_DB = { :body => body }
    result = self.class.post("/_api/user/#{@user}/database/#{database}", new_DB).parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def revoke(database: @@database)
    database = database.database if database.is_a?(ArangoDatabase)
    body = { "grant" => "none" }.to_json
    new_DB = { :body => body }
    result = self.class.post("/_api/user/#{@user}/database/#{database}", new_DB).parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def databases
    result = self.class.get("/_api/user/#{@user}/database/").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  def replace(password: , active: nil, extra: nil)
    body = {
      "passwd" => password,
      "active" => active,
      "extra" => extra
    }.delete_if{|k,v| v.nil?}.to_json
    new_DB = { :body => body }
    result = self.class.put("/_api/user/#{@user}", new_DB).parsed_response
    if @@verbose
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

  def update(password: , active: nil, extra: nil)
    body = {
      "passwd" => password,
      "active" => active,
      "extra" => extra
    }.delete_if{|k,v| v.nil?}.to_json
    new_DB = { :body => body }
    result = self.class.patch("/_api/user/#{@user}", new_DB).parsed_response
    if @@verbose
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

  def destroy
    result = self.class.delete("/_api/user/#{@user}").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end
end
