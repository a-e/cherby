module Cherby
  class CherbyError < RuntimeError; end
  class LoginFailed < CherbyError; end
  class SoapError < CherbyError; end
end # module Cherby

