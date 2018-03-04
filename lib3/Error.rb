# === ERROR ===

module Arango
  class Error < StandardError
    def initialize(message:, data: nil, code: nil, errorNum: nil, request: nil, url: nil)
      @message = message
      @data = data
      @code = code
      @errorNum = errorNum
      @request = request
      @url = url
      super(message)
    end
    attr_reader :data, :code, :message, :errorNum, :request, :url
  end
end
