# spec_helper.rb
require 'simplecov'
SimpleCov.start if ENV['COVERAGE']
require 'rspec'

ROOT_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
LIB_DIR = File.join(ROOT_DIR, 'lib')
SPEC_DIR = File.join(ROOT_DIR, 'spec')
DATA_DIR = File.join(SPEC_DIR, 'data')
CONFIG_FILE = File.join(ROOT_DIR, 'config', 'test-config.yml')
$LOAD_PATH.unshift(LIB_DIR)

RSpec.configure do |config|
end

