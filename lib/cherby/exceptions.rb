module Cherby
  class CherbyError < RuntimeError; end
  class LoginFailed < CherbyError; end
  class SoapError < CherbyError; end
  class NotFound < CherbyError; end
  class BadFormat < CherbyError; end
end # module Cherby

