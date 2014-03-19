require 'savon'
require 'nokogiri'
require 'cherby/client'
require 'cherby/incident'
require 'cherby/task'

module Cherby

  class LoginFailed < RuntimeError
  end

  class SoapError < RuntimeError
  end

  class Cherwell
    attr_reader :url, :username, :client

    def initialize(config)
      @url = config['url']
      @url.chop! if @url =~ /\/$/   # Remove any trailing slash
      @username = config['username']
      @password = config['password']
      @client = Cherby::Client.new(@url)
    end

    # Login to Cherwell using the given credentials. Return true if
    # login succeeded, or raise `LoginFailed` if login failed.
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
    def logout
      return @client.logout
    end

    # Get the Cherwell incident with the given public ID, and return an
    # Incident object.
    def incident(id)
      incident_xml = get_business_object('Incident', id)
      return Incident.new(incident_xml.to_s)
    end

    # Get the Cherwell task with the given public ID, and return a Task
    # object.
    def task(id)
      task_xml = get_business_object('Task', id)
      return Task.new(task_xml.to_s)
    end

    # Get a business object based on its public ID or RecID, and return the
    # XML response.
    #
    # Examples:
    #
    #     incident_xml = cherwell.get_business_object(
    #       'Incident', '12345')
    #
    #     note_xml = cherwell.get_business_object(
    #       'JournalNote', '93bd7e3e067f1dafb454d14cb399dda1ef3f65d36d')
    #
    # This invokes `GetBusinessObject` or `GetBusinessObjectByPublicId`,
    # depending on the length of `id`. The returned XML is the content of the
    # `GetBusinessObjectResult` or `GetBusinessObjectByPublicIdResult`.
    #
    # @param [String] name_or_id
    #   The `Name` or `IDREF` attribute of the object, specifying the type of
    #   entity you want to look up. These are represented in XML responses in
    #   the form <BusinessObject IDREF="<idref>" Name="<name>" ...>.
    #   Some allowed names: Incident, WebsiteForm, ServiceGroup, MailHistory,
    #   JournalNote, SLA
    # @param [String] id
    #   The public ID or RecID of the object. If this is 32 characters or
    #   more, it's assumed to be a RecID. For incidents, the public ID is a
    #   numeric identifier like "50629", while the RecID is a long
    #   hexadecimal string like "93bd7e3e067f1dafb454d14cb399dda1ef3f65d36d".
    #
    # @return [String]
    #   Raw XML response string.
    #
    def get_business_object(name_or_id, id)
      # Assemble the SOAP body
      body = {:busObNameOrId => name_or_id}

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
      # If a SOAP fault occurs, raise an exception
      rescue Savon::SOAPFault => e
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
    # succeeds, return the Incident instance; otherwise, return nil.
    #
    # @param [Hash] data
    #   Incident fields to initialize. All required fields must be filled
    #   in, or creation will fail. At minimum this includes :service,
    #   :sub_category, and :priority.
    #
    # @example
    #   create_incident({
    #     :service => 'Consulting Services',
    #     :sub_category => 'New/Modified Functionality',
    #     :priority => '4',
    #   })
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

    # Return the text of the last error that occurred,
    # or nil if there was no error
    def last_error
      return @client.get_last_error
    end

  end # class Cherwell
end # module Cherby

