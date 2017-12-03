# === ERROR ===

module Arango
  class Error < StandardError
    def initialize(message: , data: nil, code: code)
      @data = data
      @code = code
      super(message)
    end
    attr_reader :data, :code
  end
end
