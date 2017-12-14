module Arango
  class Batch
    def initialize(database:, boundary: "XboundaryX")
      satisfy_class?(database, "database", [Arango::Database])
      @headers = {
        "Content-Type": "multipart/form-data",
        "boundary": boundary
      }
      @boundary = boundary
      @database = database
      @client = database.client
      @queries = {}
      @id = 1
    end

    attr_reader :headers, :database, :client, :boundary
    attr_accessor :queries

    def boundary=(boundary)
      @boundary = boundary
      @headers["boundary"] = boundary
    end

    def add_query(id: @id, method:, url:, body: nil)
      id = id.to_s
      @queries[id.to_s] = {
        "id" => id,
        "method" => method,
        "url" => url,
        "body" => body
      }
      @id += 1
    end

    def execute
      body = ""
      @queries.each{|query|
        body += "--#{@boundary}\n"
        body += "Content-Type: application/x-arango-batchpart\n"
        body += "Content-Id: #{query["id"]}\n"
        body += "\n"
        body += "#{query["method"]} "
        body += "#{query["url"]} HTTP/1.1\n"
        body += "\n#{query["body"].to_json}\n" unless query["body"].nil?
      }
      body += "--#{@boundary}--\n" if queries.length > 0
      @database.request(method: "POST", url: "/_api/batch",
        body: body, skip_to_json: true, headers: @headers)
    end
  end
end
