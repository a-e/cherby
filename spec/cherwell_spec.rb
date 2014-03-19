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
      'url' => CHERWELL_WSDL,
      'username' => 'somebody',
      'password' => 'somepass',
    }
    @cherwell = Cherby::Cherwell.new(@config)
  end

  describe "#initialize" do
    it "sets configuration from a hash"
    it "creates a new Cherby::Client instance" do
      @cherwell.client.should be_a(Cherby::Client)
    end
  end #initialize

  describe "#login" do
    it "success when Cherwell returns a true status" do
      login_response = savon_response('Login', 'true')
      savon.expects(:login).with(:message => :any).
        returns(login_response)
      @cherwell.login.should be_true
    end

    it "raises LoginFailed when client.login raises any exception" do
      error = "Arbitrary exception message"
      @cherwell.client.stub(:call).with(:login, :message => anything).
        and_raise(RuntimeError.new(error))
      lambda do
        @cherwell.login
      end.should raise_error(Cherby::LoginFailed, error)
    end

    it "raises LoginFailed when Cherwell returns a false status" do
      savon.expects(:login).with(:message => :any).
        returns(savon_response('Login', 'false'))
      lambda do
        @cherwell.login
      end.should raise_error(
        Cherby::LoginFailed,
        /Cherwell returned false status/)
    end
  end #login

  describe "#logout" do
    it "returns true when Cherwell returns a true status" do
      savon.expects(:logout).with(:message => :any).
        returns(savon_response('Logout', 'true'))
      @cherwell.logout.should be_true
    end

    it "returns false when Cherwell returns a false status" do
      savon.expects(:logout).with(:message => :any).
        returns(savon_response('Logout', 'false'))
      @cherwell.logout.should be_false
    end
  end #logout

  describe "#incident" do
    it "returns a Cherby::Incident instance" do
      incident_id = '51949'
      incident_xml = File.read(File.join(DATA_DIR, 'incident.xml'))
      @cherwell.stub(:get_business_object).
        with('Incident', incident_id).
        and_return(incident_xml)
      @cherwell.incident(incident_id).should be_a(Cherby::Incident)
    end
  end #incident

  describe "#task" do
    it "returns a Cherby::Task instance" do
      task_id = '12345'
      task_xml = File.read(File.join(DATA_DIR, 'task.xml'))
      @cherwell.stub(:get_business_object).
        with('Task', task_id).
        and_return(task_xml)
      @cherwell.task(task_id).should be_a(Cherby::Task)
    end
  end #task

  describe "#get_business_object" do
    before(:each) do
      @name = 'Thing'
      @rec_id = '12345678901234567890123456789012'
      @public_id = '12345'
      @thing_xml = %Q{
        <FieldList>
          <Field Name="Name">#{@name}</Field>
          <Field Name="RecID">#{@rec_id}</Field>
        </FieldList>
      }
    end

    it "invokes :get_business_object for 32-character RecID" do
      savon.expects(:get_business_object).
        with(
          :message => {
            :busObNameOrId => @name,
            :busObRecId => @rec_id,
          }
        ).returns(
          savon_response('GetBusinessObject', @thing_xml)
        )
      @cherwell.get_business_object(@name, @rec_id)
    end

    it "invokes :get_business_object_by_public_id for < 32-character IDs" do
      savon.expects(:get_business_object_by_public_id).
        with(
          :message => {
            :busObNameOrId => @name,
            :busObPublicId => @public_id,
          }
        ).returns(
          savon_response('GetBusinessObjectByPublicId', @thing_xml)
        )
      @cherwell.get_business_object(@name, @public_id)
    end

    it "raises a Cherby::SoapError if a Savon::SOAPFault occurs"
    it "returns a raw XML response string"
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

