# spec_helper.rb
require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

require 'rspec'
require 'mustache'

ROOT_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
LIB_DIR = File.join(ROOT_DIR, 'lib')
SPEC_DIR = File.join(ROOT_DIR, 'spec')
DATA_DIR = File.join(SPEC_DIR, 'data')
XML_DIR = File.join(SPEC_DIR, 'xml')
CONFIG_FILE = File.join(ROOT_DIR, 'config', 'test-config.yml')
CHERWELL_WSDL = File.join(DATA_DIR, 'cherwell.wsdl')
$LOAD_PATH.unshift(LIB_DIR)

class XMLTemplate < Mustache
  self.template_path = XML_DIR
end

RSpec.configure do |config|
  def xml_envelope(body)
    return XMLTemplate.render_file('soap_envelope', :body => body)
  end

  def xml_response(method, body)
    wrapped_body = XMLTemplate.render_file(
      'method_response_result', :method => method, :body => body)
    return xml_envelope(wrapped_body)
  end

  def savon_response(method, body)
    return {
      :code => 200,
      :headers => {},
      :body => xml_response(method, body)
    }
  end
end

