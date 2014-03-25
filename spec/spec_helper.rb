# spec_helper.rb
require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

require 'rspec'

ROOT_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
LIB_DIR = File.join(ROOT_DIR, 'lib')
SPEC_DIR = File.join(ROOT_DIR, 'spec')
DATA_DIR = File.join(SPEC_DIR, 'data')
XML_DIR = File.join(SPEC_DIR, 'xml')
CONFIG_FILE = File.join(ROOT_DIR, 'config', 'test-config.yml')
CHERWELL_WSDL = File.join(DATA_DIR, 'cherwell.wsdl')
$LOAD_PATH.unshift(LIB_DIR)

RSpec.configure do |config|
  def xml_response(method, body)
    env_attrs = {
      'xmlns:soap' => "http://schemas.xmlsoap.org/soap/envelope/",
      'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
      'xmlns:xsd' => "http://www.w3.org/2001/XMLSchema",
    }
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['soap'].Envelope(env_attrs) do |env|
        env.Body do
          env.send(:"#{method}Response", 'xmlns' => 'http://cherwellsoftware.com') do
            env.send(:"#{method}Result", body)
          end
        end
      end
    end
    return builder.to_xml
  end

  def savon_response(method, body)
    return {
      :code => 200,
      :headers => {},
      :body => xml_response(method, body)
    }
  end
end

