module Cherby
  class CherbyError < RuntimeError; end
  class LoginFailed < CherbyError; end
  class NotFound < CherbyError; end
  class BadFormat < CherbyError; end

  class SoapError < CherbyError
    attr_reader :http
    def initialize(message, http=nil)
      super(message)
      @http = http
    end
  end
end # module Cherby

