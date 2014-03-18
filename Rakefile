# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = [ '-c', '-f', 'doc' ]
end

task :default => :spec

ROOT_DIR = File.expand_path(File.dirname(__FILE__))

desc "Open pry REPL with some basic objects already setup: jira, cherwell, config"
task :pry, [:config_file] do |t, args|
  $: << File.join(ROOT_DIR, 'lib')
  require 'pry'
  require 'cherby'

  args.with_defaults(:config_file => File.join(ROOT_DIR, 'config', 'test-config.yml'))
  puts "args: #{args.inspect}"

  config_file = args[:config_file]
  # FIXME
  #config = JiraCher::Config::load(config_file)

  cherwell = Cherby::Cherwell.new(config['cherwell'])

  #puts "logging into Cherwell..."
  #cherwell.login

  puts "cherwell.url = #{cherwell.url} cherwell.username = #{cherwell.username}"

  binding.pry
end
