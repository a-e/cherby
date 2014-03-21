require_relative 'spec_helper'
require 'cherby/cherwell'
require 'cherby/exceptions'
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
    @cherwell = Cherby::Cherwell.new(CHERWELL_WSDL)
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

    it "raises Cherby::LoginFailed when client.login raises any exception" do
      error = "Arbitrary exception message"
      @cherwell.client.stub(:call).with(:login, :message => anything).
        and_raise(RuntimeError.new(error))
      lambda do
        @cherwell.login
      end.should raise_error(Cherby::LoginFailed, error)
    end

    it "raises Cherby::LoginFailed when Cherwell returns a false status" do
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
      @cherwell.stub(:get_object_xml).
        with('Incident', incident_id).
        and_return(incident_xml)
      @cherwell.incident(incident_id).should be_a(Cherby::Incident)
    end
  end #incident

  describe "#task" do
    it "returns a Cherby::Task instance" do
      task_id = '12345'
      task_xml = File.read(File.join(DATA_DIR, 'task.xml'))
      @cherwell.stub(:get_object_xml).
        with('Task', task_id).
        and_return(task_xml)
      @cherwell.task(task_id).should be_a(Cherby::Task)
    end
  end #task

  describe "#get_object_xml" do
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

    it "invokes GetBusinessObject for 32-character RecID" do
      savon.expects(:get_business_object).with(
        :message => {
          :busObNameOrId => @name,
          :busObRecId => @rec_id,
        }
      ).returns(
        savon_response('GetBusinessObject', @thing_xml)
      )
      @cherwell.get_object_xml(@name, @rec_id)
    end

    it "invokes GetBusinessObjectByPublicId for < 32-character IDs" do
      savon.expects(:get_business_object_by_public_id).with(
        :message => {
          :busObNameOrId => @name,
          :busObPublicId => @public_id,
        }
      ).returns(
        savon_response('GetBusinessObjectByPublicId', @thing_xml)
      )
      @cherwell.get_object_xml(@name, @public_id)
    end

    it "returns a raw XML response string" do
      xml = "<Foo>Bar</Foo>"
      savon.expects(:get_business_object_by_public_id).with(
        :message => :any
      ).returns(
        savon_response('GetBusinessObjectByPublicId', xml)
      )
      result = @cherwell.get_object_xml(@name, @public_id)
      result.should == xml
    end

    it "raises a Cherby::SoapError if a Savon::Error occurs" do
      soap_fault = Savon::Error.new("Kaboom")
      @cherwell.client.stub(:call).and_raise(soap_fault)
      lambda do
        @cherwell.get_object_xml(@name, @public_id)
      end.should raise_error(
        Cherby::SoapError, /Kaboom/)
    end
  end #get_object_xml

  describe "#update_object_xml" do
    before(:each) do
      @public_id = '80909'
      @xml = %Q{
        <Foo>Bar</Foo>
      }
    end

    it "invokes UpdateBusinessObjectByPublicId with the given XML" do
      savon.expects(:update_business_object_by_public_id).with(
        :message => {
          :busObNameOrId => 'Incident',
          :busObPublicId => @public_id,
          :updateXml => @xml
        }
      ).returns(
        savon_response('UpdateBusinessObjectByPublicId', 'true')
      )
      @cherwell.stub(:last_error => nil)
      @cherwell.update_object_xml('Incident', @public_id, @xml)
    end

    it "returns the #last_error string" do
      savon.expects(:update_business_object_by_public_id).
        with(:message => :any).
        returns(savon_response('UpdateBusinessObjectByPublicId', 'false'))

      error_message = "Failed to update object"
      @cherwell.stub(:last_error => error_message)
      result = @cherwell.update_object_xml('Incident', @public_id, @xml)
      result.should == error_message
    end
  end #update_object_xml

  describe "#save_incident" do
    before(:each) do
      @public_id = '62521'
      @incident_data = {
        :incident_id => @public_id,
        :service => 'Consulting Services',
        :sub_category => 'New/Modified Functionality',
        :priority => '4',
      }
      @incident = Cherby::Incident.create(@incident_data)
      @cherwell.stub(:last_error => nil)
    end

    it "invokes UpdateBusinessObjectByPublicId with the Incident XML" do
      savon.expects(:update_business_object_by_public_id).with(
        :message => {
          :busObNameOrId => 'Incident',
          :busObPublicId => @public_id,
          :updateXml => @incident.to_xml
        }
      ).returns(
        savon_response('UpdateBusinessObjectByPublicId', 'true')
      )
      @cherwell.save_incident(@incident)
    end
  end #save_incident

  describe "#save_task" do
    before(:each) do
      @public_id = '90210'
      @task_data = {
        :task_id => @public_id,
        :parent_id => '90000'
      }
      @task = Cherby::Task.create(@task_data)
      @cherwell.stub(:last_error => nil)
    end

    it "invokes UpdateBusinessObjectByPublicId with the Task XML" do
      savon.expects(:update_business_object_by_public_id).with(
        :message => {
          :busObNameOrId => 'Task',
          :busObPublicId => @public_id,
          :updateXml => @task.to_xml
        }
      ).returns(
        savon_response('UpdateBusinessObjectByPublicId', 'true')
      )
      @cherwell.save_task(@task)
    end
  end #save_task

  describe "#create_incident" do
    before(:each) do
      @incident_data = {
        :service => 'Consulting Services',
        :sub_category => 'New/Modified Functionality',
        :priority => '4',
      }
      @public_id = '54321'
    end

    it "invokes CreateBusinessObject with incident XML" do
      savon.expects(:create_business_object).with(
        :message => {
          :busObNameOrId => 'Incident',
          :creationXml => Cherby::Incident.create(@incident_data).to_xml
        }
      ).returns(
        savon_response('CreateBusinessObject', @public_id)
      )
      @cherwell.create_incident(@incident_data)
    end

    it "returns a Cherby::Incident instance with IncidentID set" do
      savon.expects(:create_business_object).with(:message => :any).returns(
        savon_response('CreateBusinessObject', @public_id)
      )
      result = @cherwell.create_incident(@incident_data)
      result.should be_a(Cherby::Incident)
      result['IncidentID'].should == @public_id
    end

    it "returns nil if incident creation failed (Cherwell returned nil)" do
      savon.expects(:create_business_object).with(:message => :any).returns(
        savon_response('CreateBusinessObject', nil)
      )
      result = @cherwell.create_incident(@incident_data)
      result.should be_nil
    end
  end #create_incident

  describe "#last_error" do
    it "returns the GetLastError response text" do
      error_message = "Object reference not set to an instance of an object"
      savon.expects(:get_last_error).with(:message => {}).returns(
        savon_response('GetLastError', error_message)
      )
      @cherwell.last_error.should == error_message
    end

    it "returns nil if GetLastError returns nil" do
      savon.expects(:get_last_error).with(:message => {}).returns(
        savon_response('GetLastError', nil)
      )
      @cherwell.last_error.should be_nil
    end
  end #last_error

end # describe Cherby::Cherwell

