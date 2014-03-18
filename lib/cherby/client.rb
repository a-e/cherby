require 'savon'

module Cherby
  # Convenience wrapper for Cherwell SOAP API
  class Client < Savon::Client

    # Create a Cherwell Client for the SOAP API at the given base URL
    def initialize(base_url)
      if File.exist?(base_url)
        wsdl_url = base_url
      elsif base_url =~ /^http/
        if base_url.downcase.end_with?('?wsdl')
          wsdl_url = base_url
        else
          wsdl_url = "#{base_url}?WSDL"
        end
      elsif base_url !~ /^http/
        raise ArgumentError, "Client URL must be a local file, or begin with http"
      end
      super(:wsdl => wsdl_url)
    end

    # Call #request with the given method, passing the given SOAP body.
    # Return the content of the `<[MethodName]Result>` element.
    def call_wrap(meth, body={})
      meth = meth.to_sym
      if !known_methods.include?(meth)
        raise ArgumentError, "Unknown Cherwell SOAP API method: #{meth}"
      end
      # FIXME: Let Savon handle this snake_case stuff
      # Each request has a *_response containing a *_result
      response_field = (meth.to_s + '_response').to_sym
      result_field = (meth.to_s + '_result').to_sym
      # Submit the request
      response = self.call(meth, :message => body)
      return response.to_hash[response_field][result_field]
    end

    # If a method in #known_methods is called, send it as a request
    def method_missing(meth, *args, &block)
      if known_methods.include?(meth)
        call_wrap(meth, args.first)
      else
        super
      end
    end

    # Valid methods in the Cherwell SOAP API
    def known_methods
      return self.operations.sort
    end

  end
end

