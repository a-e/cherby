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

  before(:each) do
    @client = Cherby::Client.new(CHERWELL_WSDL)
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

  describe "#call_wrap" do
    it "accepts string method name" do
      savon.expects(:login).
        with(:message => :any).
        returns(savon_response('Login', 'true'))
      @client.call_wrap('login')
    end

    it "accepts symbol method name" do
      savon.expects(:login).
        with(:message => :any).
        returns(savon_response('Login', 'true'))
      @client.call_wrap(:login)
    end

    it "raises ArgumentError if method is unknown" do
      lambda do
        @client.call_wrap(:bogus)
      end.should raise_error(
        ArgumentError, /Unknown Cherwell SOAP API method: bogus/)
    end
  end #call

  describe "#method_missing" do
    it "converts positional arguments to a Hash appropriate for the method" do
      savon.expects(:login).
        with(:message => {:userId => 'username', :password => 'password'}).
        returns(savon_response('Login', 'true'))
      @client.login('username', 'password')
    end

    it "passes hash argument as-is" do
      message = {:userId => 'username', :password => 'password'}
      savon.expects(:login).
        with(:message => message).
        returns(savon_response('Login', 'true'))
      @client.login(message)
    end

    it "raises an exception if method is not in known_methods" do
      lambda do
        @client.bogus_method
      end.should raise_error(NoMethodError)
    end
  end #method_missing

  describe "#known_methods" do
    it "returns an array of symbolic method names" do
      methods = @client.known_methods
      methods.should be_a(Array)
      methods.each do |meth|
        meth.should be_a(Symbol)
      end
    end
  end #known_methods

  describe "#params_for_method" do
    it "returns a hash of parameters and their type info" do
      params = @client.params_for_method(:login)
      params.should include(:password)
      params.should include(:userId)
    end

    it "returns an empty hash if method has no parameters" do
      @client.params_for_method(:logout).should == {}
    end

    it "returns an empty hash for unknown method" do
      @client.params_for_method(:bogus).should == {}
    end
  end #params_for_method

  describe "#args_to_hash" do
    it "returns a Hash of :paramName => value" do
      hash = @client.args_to_hash(:login, 'username', 'password')
      hash.should == {
        :userId => 'username',
        :password => 'password'
      }
    end

    it "raises ArgumentError if wrong number of args given" do
      lambda do
        @client.args_to_hash(:login, 'username')
      end.should raise_error(
        ArgumentError, /Wrong number of arguments/)
    end
  end
end # Cherby::Client
