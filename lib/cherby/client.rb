require 'savon'

module Cherby
  # Cherwell SOAP Client wrapper
  class Client < Savon::Client

    # Create a Cherwell Client for the SOAP API at the given base URL.
    #
    # @param [String] base_url
    #   Full URL to the Cherwell web service WSDL, typically something
    #   like "http://my.hostname.com/CherwellService/api.asmx?WSDL".
    #   The `http://` and `?WSDL` parts are automatically added if missing.
    #
    def initialize(base_url, verbose_logging=false)
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
      super(:wsdl => wsdl_url, :log => verbose_logging)
    end

    # Allow setting cookies
    attr_accessor :cookies

    # Call a given SOAP method with an optional body.
    #
    # @example
    #   client.call_wrap(:login, {:userId => 'garak', :pasword => 'fabric'})
    #   # => true
    #
    # @param [Symbol] method
    #   Cherwell API method name, as a `:snake_case_symbol`.
    #   Must be one of the methods returned by `#known_methods`.
    # @param [Hash<String>] body
    #   Message body to pass to the method.
    #
    # @return [String]
    #   Content found inside the returned XML document's `<[MethodName]Result>`
    #   element.
    #
    def call_wrap(method, body={})
      method = method.to_sym
      if !known_methods.include?(method)
        raise ArgumentError, "Unknown Cherwell SOAP API method: #{method}"
      end
      # FIXME: Let Savon handle this snake_case stuff
      # Each request has a *_response containing a *_result
      response_field = (method.to_s + '_response').to_sym
      result_field = (method.to_s + '_result').to_sym
      # Submit the request
      response = self.call(method, :message => body, :cookies => self.cookies)
      return response.to_hash[response_field][result_field]
    end

    # If a method in `#known_methods` is called, send it as a request.
    #
    # @param [Symbol] method
    #   Cherwell API method name, as a `:snake_case_symbol`.
    #   Must be one of the methods returned by `#known_methods`.
    #
    # @param [String, Hash] args
    #   Positional arguments (strings) or a hash of arguments
    #   (`:symbol => 'String'`) to pass to the method.
    #
    # @example
    #   # Login with positional arguments:
    #   client.login('sisko', 'baseball')
    #   # or a Hash of arguments:
    #   client.login(:userId => 'sisko', :password => 'baseball')
    #
    #   # Get a BusinessObject definition with positional arguments:
    #   client.get_business_object_definition('JournalNote')
    #   # or a Hash of arguments:
    #   client.get_business_object_definition(:nameOrId => 'JournalNote')
    #
    def method_missing(method, *args, &block)
      if known_methods.include?(method)
        if args.first.is_a?(Hash)
          call_wrap(method, args.first)
        else
          hash_args = args_to_hash(method, *args)
          call_wrap(method, hash_args)
        end
      else
        super
      end
    end

    # Valid methods in the Cherwell SOAP API
    #
    # @return [Array<Symbol>]
    #
    def known_methods
      return self.operations.sort
    end

    # Return parameters for the given Cherwell API method.
    #
    # @param [Symbol] method
    #   Cherwell API method name, as a `:snake_case_symbol`.
    #   Must be one of the methods returned by `#known_methods`.
    #
    # @return [Hash]
    #   Parameter definitions for the given method, or an empty
    #   hash if the method is unknown.
    #
    def params_for_method(method)
      if @wsdl.operations.include?(method)
        return @wsdl.operations[method][:parameters] || {}
      else
        return {}
      end
    end

    # Convert positional parameters into a `:key => value` hash,
    # with parameter names inferred from `#params_for_method`.
    #
    # @example
    #   client.args_to_hash(:login, 'odo', 'nerys')
    #   # => {:userId => 'odo', :password => 'nerys'}
    #
    # @param [Symbol] method
    #   Cherwell API method name, as a `:snake_case_symbol`.
    #   Must be one of the methods returned by `#known_methods`.
    # @param [String] args
    #   Positional argument values
    #
    # @return [Hash<String>]
    #   `:key => value` for each positional argument.
    #
    # @raise [ArgumentError]
    #   If the given number of `args` doesn't match the number of parameters
    #   expected by `method`.
    #
    def args_to_hash(method, *args)
      params = params_for_method(method)
      if params.count != args.count
        raise ArgumentError.new(
          "Wrong number of arguments (#{args.count} for #{params.count})")
      end
      return Hash[params.keys.zip(args)]
    end
  end
end

