require 'savon'
require 'nokogiri'
require 'cherby/client'
require 'cherby/incident'
require 'cherby/task'
require 'cherby/exceptions'

module Cherby
  # Top-level Cherwell interface
  class Cherwell
    attr_reader :url, :username, :client

    # Connect to a Cherwell server.
    #
    # @param [String] web_service_url
    #   Full URL to the Cherwell web service API (typically ending in
    #   `api.asmx`)
    # @param [String] username
    #   Default Cherwell user ID to use
    # @param [String] password
    #   Default Cherwell password to use
    #
    def initialize(web_service_url, username=nil, password=nil)
      @url = web_service_url
      @url.chop! if @url =~ /\/$/   # Remove any trailing slash
      @username = username
      @password = password
      @client = Cherby::Client.new(@url)
    end

    # Login to Cherwell using the given credentials. Return true if
    # login succeeded, or raise `LoginFailed` if login failed.
    #
    # @param [String] username
    #   User ID to login with. If omitted, the username that was passed to
    #   `Cherwell.new` is used.
    # @param [String] password
    #   Password to login with. If omitted, the password that was passed to
    #   `Cherwell.new` is used.
    #
    # @return [Boolean]
    #   `true` if login was successful
    #
    # @raise [LoginFailed]
    #   If login failed for any reason
    #
    def login(username=nil, password=nil)
      creds = {
        :userId => username || @username,
        :password => password || @password,
      }
      begin
        response = @client.call(:login, :message => creds)
      rescue => e
        # This can happen if a bad URL is given
        raise LoginFailed, e.message
      else
        if response.body[:login_response][:login_result] == true
          # FIXME: Using the workaround described in this issue:
          #   https://github.com/savonrb/savon/issues/363
          # because the version recommended in the documentation:
          #   auth_cookies = response.http.cookies
          # does not work, giving:
          #   NoMethodError: undefined method `cookies' for #<HTTPI::Response:0x...>
          @client.globals[:headers] = {"Cookie" => response.http.headers["Set-Cookie"]}
          return true
        # This can happen if invalid credentials are given
        else
          raise LoginFailed, "Cherwell returned false status"
        end
      end
    end

    # Log out of Cherwell.
    #
    # @return [Boolean]
    #   Logout response as reported by Cherwell.
    #
    def logout
      return @client.logout
    end

    # Get the Cherwell incident with the given public ID, and return an
    # Incident object.
    #
    # @return [Incident]
    #
    def incident(id)
      incident_xml = get_object_xml('Incident', id)
      return Incident.new(incident_xml.to_s)
    end

    # Get the Cherwell task with the given public ID, and return a Task
    # object.
    #
    # @return [Task]
    #
    def task(id)
      task_xml = get_object_xml('Task', id)
      return Task.new(task_xml.to_s)
    end

    # Get a business object based on its public ID or RecID, and return the
    # XML response.
    #
    # @example
    #   incident_xml = cherwell.get_object_xml(
    #     'Incident', '12345')
    #
    #   note_xml = cherwell.get_object_xml(
    #     'JournalNote', '93bd7e3e067f1dafb454d14cb399dda1ef3f65d36d')
    #
    # @param [String] object_type
    #   What type of object to fetch, for example "Incident", "Customer",
    #   "Task", "JournalNote", "SLA" etc. May also be the `IDREF` of an
    #   object type. Cherwell's API knows this as `busObNameOrId`.
    # @param [String] id
    #   The public ID or RecID of the object. If this is 32 characters or
    #   more, it's assumed to be a RecID. For incidents, the public ID is a
    #   numeric identifier like "50629", while the RecID is a long
    #   hexadecimal string like "93bd7e3e067f1dafb454d14cb399dda1ef3f65d36d".
    #
    # This invokes `GetBusinessObject` or `GetBusinessObjectByPublicId`,
    # depending on the length of `id`. The returned XML is the content of the
    # `GetBusinessObjectResult` or `GetBusinessObjectByPublicIdResult`.
    #
    # @return [String]
    #   Raw XML response string.
    #
    def get_object_xml(object_type, id)
      # Assemble the SOAP body
      body = {:busObNameOrId => object_type}

      # If ID is really long, it's probably a RecID
      if id.to_s.length >= 32
        method = :get_business_object
        body[:busObRecId] = id
      # Otherwise, assume it's a public ID
      else
        method = :get_business_object_by_public_id
        body[:busObPublicId] = id
      end

      begin
        result = @client.call_wrap(method, body)
      rescue Savon::Error => e
        raise SoapError, e.message
      else
        return result
      end
    end


    # Update a given Cherwell object by submitting its XML to the SOAP
    # interface.
    #
    # @param [String] object_type
    #   The kind of object you're updating ('Incident', 'Task'), or the
    #   IDREF of the object type.
    # @param [String] id
    #   The public ID of the object
    # @param [String] xml
    #   The XML body containing all the updates you want to make
    #
    def update_object_xml(object_type, id, xml)
      @client.update_business_object_by_public_id({
        :busObNameOrId => object_type,
        :busObPublicId => id,
        :updateXml => xml
      })
      return last_error
    end

    # Save the given Cherwell incident
    def save_incident(incident)
      update_object_xml('Incident', incident.id, incident.to_xml)
    end

    # Save the given Cherwell task
    def save_task(task)
      update_object_xml('Task', task.id, task.to_xml)
    end

    # Create a new Cherwell incident with the given data. If creation
    # succeeds, return the Incident instance; otherwise, return `nil`.
    #
    # @example
    #   create_incident(
    #     :service => 'Consulting Services',
    #     :sub_category => 'New/Modified Functionality',
    #     :priority => '4',
    #   )
    #
    # @param [Hash] data
    #   Incident fields to initialize. All required fields must be filled
    #   in, or creation will fail. At minimum this includes `:service`,
    #   `:sub_category`, and `:priority`.
    #
    # @return [Incident, nil]
    #   The created incident, or `nil` if creation failed.
    #
    def create_incident(data)
      incident = Incident.create(data)
      result = @client.create_business_object({
        :busObNameOrId => 'Incident',
        :creationXml => incident.to_xml
      })

      # Result contains the public ID of the new incident, or nil if the
      # incident-creation failed.
      if !result.nil?
        incident['IncidentID'] = result
        return incident
      else
        return nil
      end
    end

    # Get the last error reported by Cherwell.
    #
    # @return [String, nil]
    #   Text of the last error that occurred, or `nil` if there was no error.
    #
    def last_error
      return @client.get_last_error
    end

    # Get a business object definition as a hash
    # ex.
    #     get_object_definition('Incident')
    #
    # TODO: Use this as the basis for building templates, intead of mustache
    #
    def get_object_definition(object_type)
      result = {}
      definition = @client.get_business_object_definition(object_type)
      selector = 'BusinessObjectDef > FieldList > Field'
      Nokogiri::XML(definition).css(selector).map do |field|
        result[field['Name']] = field.css('Description').inner_html
      end
      return result
    end

  end # class Cherwell
end # module Cherby

