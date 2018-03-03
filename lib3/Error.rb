# === ERROR ===

module Arango
  class Error < StandardError
    def initialize(message:, data: nil, code: nil, errorNum: nil)
      @message = message
      @data = data
      @code = code
      @errorNum = errorNum
      super(message)
    end
    attr_reader :data, :code, :message, :errorNum
  end
end
