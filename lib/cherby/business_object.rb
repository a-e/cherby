require 'mustache'
require 'nokogiri'

module Cherby
  # Cherwell BusinessObject wrapper, with data represented as an XML DOM
  class BusinessObject

    # Override this with the value of the BusinessObject's 'Name' attribute
    @object_name = ''
    # Override this with the name of the Mustache XML template used to render
    # your BusinessObject
    @template = ''
    # Fill this with default values for new instances of your BusinessObject
    @default_values = {}

    class << self
      attr_accessor :object_name, :template, :default_values, :template_path
    end

    # Create a new BusinessObject subclass instance from the given hash of
    # options.
    def self.create(options={})
      if self.template.empty?
        # TODO: Exception subclass
        raise RuntimeError, "No template defined for BusinessObject"
      end
      Mustache.template_path = File.join(File.dirname(__FILE__), 'templates')
      xml = Mustache.render_file(
        self.template, self.default_values.merge(options))
      return self.new(xml)
    end

    # Instance methods

    attr_reader :dom

    # Create a new instance populated with the given XML string
    def initialize(xml)
      @dom = Nokogiri::XML(xml)
    end

    # Return the XML representation of this BusinessObject
    def to_xml
      return @dom.to_xml
    end

    # Return the node of the field with the given name.
    def get_field_node(field_name)
      selector = "BusinessObject[@Name=#{self.class.object_name}] Field[@Name=#{field_name}]"
      return @dom.css(selector).first
    end

    # Return a hash of field names and values
    def field_values
      result = {}
      selector = "BusinessObject[@Name=#{self.class.object_name}] > FieldList > Field"
      @dom.css(selector).collect do |node|
        result[node['Name']] = node.content
      end
      return result
    end

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
      if last_mod.nil?
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
      if field = get_field_node(field_name)
        return field.content
      end
    end

    # Modify the content in the field with the given name.
    def []=(field_name, value)
      if field = get_field_node(field_name)
        field.content = value.to_s
      end
    end
  end
end
