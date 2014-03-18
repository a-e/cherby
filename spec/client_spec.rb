require_relative 'spec_helper'
require 'cherby/client'
require 'savon/mock/spec_helper'

describe Cherby::Client do
  include Savon::SpecHelper

  before(:all) do
    savon.mock!
  end

  after(:all) do
    savon.unmock!
  end

  describe "#initialize" do
    it "raises ArgumentError if URL does not begin with http" do
      lambda do
        Cherby::Client.new("ftp://example.com")
      end.should raise_error(
        ArgumentError, /Client URL must be a local file, or begin with http/)
    end

    it "can get WSDL from a local filename" do
      client = Cherby::Client.new(CHERWELL_WSDL)
      client.globals[:wsdl].should == CHERWELL_WSDL
    end

    it "appends '?WSDL' if an HTTP URL is missing it" do
      client = Cherby::Client.new("http://example.com")
      client.globals[:wsdl].should == "http://example.com?WSDL"
    end

    it "does not append another '?WSDL' if the HTTP URL already has it" do
      client = Cherby::Client.new("http://example.com?WSDL")
      client.globals[:wsdl].should == "http://example.com?WSDL"
    end
  end #initialize

  describe "#call" do
    before(:each) do
      @client = Cherby::Client.new(CHERWELL_WSDL)
    end

    it "accepts string method name" do
      pending("Need to reformat mock XML data; Savon can't parse it")
      xml = File.read(File.join(DATA_DIR, 'task.xml'))
      response = {:code => 200, :headers => {}, :body => xml}
      savon.expects(:get_dashboard).with(:message => {}).returns(response)
      @client.call('get_dashboard')
    end

    it "accepts symbol method name"
    it "raises ArgumentError if method is unknown"
  end #call

  describe "#method_missing" do
    it "TODO"
  end #method_missing

  describe "#known_methods" do
    it "returns an array of symbolic method names" do
      @client = Cherby::Client.new(CHERWELL_WSDL)
      methods = @client.known_methods
      methods.should be_a(Array)
      methods.each do |meth|
        meth.should be_a(Symbol)
      end
    end
  end #known_methods

end # Cherby::Client
