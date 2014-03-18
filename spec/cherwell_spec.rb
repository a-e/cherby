require_relative 'spec_helper'
require 'cherby/cherwell'
require 'savon/mock/spec_helper'

describe Cherby::Cherwell do
  include Savon::SpecHelper

  before(:all) do
    savon.mock!
  end

  after(:all) do
    savon.unmock!
  end

  before(:each) do
    # TODO: Mock this!
    @config = {
      'url' => 'http://cherwell.example.com/',
      'username' => 'somebody',
      'password' => 'somepass',
    }
    @cherwell = Cherby::Cherwell.new(@config)
  end

  describe "#initialize" do
    it "accepts hash configuration"
  end #initialize

  describe "#login" do
    it "success when Cherwell returns a true status" do
      login_true_xml = File.read(File.join(DATA_DIR, 'cherwell_login_true.xml'))
      login_true_response = {:code => 200, :headers => {}, :body => login_true_xml}

      savon.expects(:login).with(:message => :any).returns(login_true_response)
      @cherwell.login.should be_true
    end

    it "raises LoginFailed when client.login raises any exception" do
      error = "Arbitrary exception message"
      @cherwell.client.stub(:login).and_raise(RuntimeError.new(error))
      lambda do
        @cherwell.login
      end.should raise_error(Cherby::LoginFailed, error)
    end

    it "raises LoginFailed when Cherwell returns a false status" do
      login_false_xml = File.read(File.join(DATA_DIR, 'cherwell_login_false.xml'))
      login_false_response = {:code => 200, :headers => {}, :body => login_false_xml}

      savon.expects(:login).with(:message => :any).returns(login_false_response)
      lambda do
        @cherwell.login
      end.should raise_error(
        Cherby::LoginFailed,
        /Cherwell returned false status/)
    end
  end #login

  describe "#logout" do
    it "TODO"
  end #logout

  describe "#incident" do
    it "TODO"
  end #incident

  describe "#task" do
    it "TODO"
  end #task

  describe "#get_business_object" do
    it "TODO"
  end #get_business_object

  describe "#update_object_xml" do
    it "TODO"
  end #update_object_xml

  describe "#save_task" do
    it "TODO"
  end #save_task

  describe "#create_incident" do
    it "TODO"
  end #create_incident

  describe "#last_error" do
    it "TODO"
  end #last_error

end # describe Cherby::Cherwell

