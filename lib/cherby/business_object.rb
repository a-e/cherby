require 'nokogiri'

module Cherby
  # Cherwell BusinessObject wrapper, with data represented as an XML DOM
  class BusinessObject

    # Override this with the value of the BusinessObject's 'Name' attribute
    @object_name = ''
    # Fill this with default values for new instances of your BusinessObject
    @default_values = {}

    class << self
      attr_accessor :object_name, :default_values
    end

    # Create a new BusinessObject subclass instance from the given hash of
    # 'FieldName' => 'Field Value'.
    def self.create(fields={})
      type_name = self.object_name
      builder = Nokogiri::XML::Builder.new {
        BusinessObject_('Name' => type_name, 'RecID' => 'TODO') {
          FieldList_ {
            fields.each { |name, value|
              Field_(value, 'Name' => name)
            }
          }
          RelationshipList_ { }
        }
      }
      return self.new(builder.to_xml)
    end

    # Instance methods

    attr_reader :dom

    # Create a new BusinessObject instance from the given XML string.
    def initialize(xml)
      @dom = Nokogiri::XML(xml)
      check_dom_format!
    end

    # Ensure the @dom is in the expected format for BusinessObjects.
    #
    # @raise [Cherby::BadFormat]
    #   If the DOM's structure is incorrect
    #
    def check_dom_format!
      # Ensure XML is in expected format for BusinessObjects
      if @dom.css('BusinessObject').empty?
        raise Cherby::BadFormat.new(
          "BusinessObject XML is missing 'BusinessObject' element")
      elsif @dom.css('BusinessObject > FieldList').empty?
        raise Cherby::BadFormat.new(
          "BusinessObject XML is missing 'BusinessObject > FieldList' element")
      end
      return true
    end

    # Return the XML representation of this BusinessObject
    def to_xml
      return @dom.to_xml
    end

    # Return the node of the field with the given name.
    #
    # @param [String] field_name
    #   The `Name` attribute of the `Field` element to get.
    #
    # @return [Nokogiri::XML::Node, nil]
    #   The node for the `Field` element, or `nil` if no Field
    #   with the given `Name` exists.
    #
    def get_field_node(field_name)
      check_dom_format!
      selector = "BusinessObject > FieldList > Field[@Name=#{field_name}]"
      return @dom.css(selector).first
    end

    # Get a `Field` node with the given name, or create one if it doesn't exist.
    #
    # @param [String] field_name
    #   The `Name` attribute of the `Field` element to get or create.
    #
    # @return [Nokogiri::XML::Node]
    #   The node for the existing or new `Field` element.
    #
    def get_or_create_field_node(field_name)
      element = get_field_node(field_name)
      if element.nil?
        element = Nokogiri::XML::Node.new('Field', @dom)
        element['Name'] = field_name
        @dom.at_css("BusinessObject > FieldList").add_child(element)
      end
      return element
    end

    # Return a hash of field names and values
    def to_hash
      result = {}
      selector = "BusinessObject > FieldList > Field"
      @dom.css(selector).each do |node|
        result[node['Name']] = node.content
      end
      return result
    end
    alias :field_values :to_hash # For backwards compatibility


    # Parse a Cherwell date/time string and return a DateTime object in UTC.
    #
    # This method mostly exists to work around the fact that Cherwell does
    # not report a time zone offset in its datestamps. Since a BusinessObject
    # may be initialized from a Jira entity (which *does* store time zone
    # offset), any dt_string that includes a time zone offset at the end is
    # correctly included in the result.
    #
    # @param [String] dt_string
    #   The date/time string to parse. May or may not include a trailing
    #   [+-]HH:MM or [+-]HHMM.
    #
    # @param [Integer] tz_offset
    #   Offset in hours (positive or negative) between UTC and the given
    #   `dt_string`. For example, Eastern Time is `-5`. This is ONLY used if
    #   `dt_string` does NOT include a trailing offset component.
    #
    def self.parse_datetime(dt_string, tz_offset=-5)
      begin
        result = DateTime.parse(dt_string)
      rescue
        raise ArgumentError, "Could not parse date/time '#{dt_string}'"
      end
      # If offset was part of the dt_string, use new_offset to get UTC
      if dt_string =~ /[+-]\d\d:?\d\d$/
        return result.new_offset(0)
      # Otherwise, subtract the numeric offset to get UTC time
      else
        return result - Rational(tz_offset.to_i, 24)
      end
    end

    # Return the last-modified date/time of this BusinessObject
    # (LastModDateTime converted to DateTime)
    def modified
      last_mod = self['LastModDateTime']
      if last_mod.nil? || last_mod.empty?
        raise RuntimeError, "BusinessObject is missing LastModDateTime field."
      end
      begin
        return BusinessObject.parse_datetime(last_mod)
      rescue(ArgumentError)
        raise RuntimeError, "Cannot parse LastModDateTime: '#{last_mod}'"
      end
    end

    # Return the last-modified time as a human-readable string
    def mod_s
      return modified.strftime('%Y-%m-%d %H:%M:%S')
    end

    # Return True if this BusinessObject was modified more recently than
    # another BusinessObject.
    def newer_than?(business_object)
      return modified > business_object.modified
    end

    # Return the content in the field with the given name.
    def [](field_name)
      field = get_field_node(field_name)
      return field.content if field
      return nil
    end

    # Modify the content in the field with the given name.
    def []=(field_name, value)
      field = get_or_create_field_node(field_name)
      field.content = value.to_s
    end

    # Copy designated fields from one BusinessObject to another.
    #
    # @example
    #   object_a.copy_fields_from(object_b, 'Status', 'Description')
    #   # object_a['Status']      = object_b['Status']
    #   # object_a['Description'] = object_b['Description']
    #
    # @param [BusinessObject] other_object
    #   The object to copy field values from
    # @param [Array<String>] field_names
    #   Names of fields whose values you want to copy
    #
    def copy_fields_from(other_object, *field_names)
      field_names.each do |field|
        self[field] = other_object[field]
      end
    end

  end
end
