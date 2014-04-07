require_relative 'spec_helper'
require 'cherby/business_object'
require 'cherby/exceptions'

# Some BusinessObject subclasses to test with
class MySubclass < Cherby::BusinessObject; end

describe Cherby::BusinessObject do
  context "Class methods" do
    describe "#object_type" do
      it "returns the plain class name as a string" do
        MySubclass.object_type.should == 'MySubclass'
      end
    end #object_type

    describe "#create" do
      it "uses object_type as the BusinessObject `Name` attribute" do
        obj = MySubclass.create({})
        obj.dom.css("BusinessObject").first.attr('Name').should == 'MySubclass'
      end

      it "sets options in the DOM" do
        obj = MySubclass.create({'First' => 'Eric', 'Last' => 'Idle'})
        first_name = obj.dom.css("BusinessObject[@Name=MySubclass] Field[@Name=First]").first
        last_name = obj.dom.css("BusinessObject[@Name=MySubclass] Field[@Name=Last]").first
        first_name.content.should == "Eric"
        last_name.content.should == "Idle"
      end
    end #create

    describe "#parse_datetime" do
      it "works with timezone offset" do
        bo = Cherby::BusinessObject
        dt = bo.parse_datetime("2012-02-09T09:42:13-05:00")
        dt.to_s.should == "2012-02-09T14:42:13+00:00"

        dt = bo.parse_datetime("2012-02-09T09:42:13.123-0500")
        dt.to_s.should == "2012-02-09T14:42:13+00:00"
      end

      it "works without timezone offset" do
        bo = Cherby::BusinessObject
        dt = bo.parse_datetime("2012-02-09T09:42:13", -5)
        dt.to_s.should == "2012-02-09T14:42:13+00:00"
      end

      it "raises ArgumentError for invalid datetime string" do
        bo = Cherby::BusinessObject
        lambda do
          bo.parse_datetime("bogus-datetime")
        end.should raise_error(ArgumentError, /Could not parse/)
      end

    end #parse_datetime

  end # Class methods


  context "Instance methods" do
    describe "#object_type" do
      it "returns the plain class name as a string" do
        obj = MySubclass.create({})
        obj.object_type.should == 'MySubclass'
      end
    end #object_type

    describe "#initialize" do
      it "accepts an XML string" do
        xml = %Q{
          <BusinessObject Name="MySubclass">
            <FieldList>
              <Field Name="First">Eric</Field>
              <Field Name="Last">Idle</Field>
            </FieldList>
          </BusinessObject>
        }
        obj = MySubclass.new(xml)
        first_name = obj.dom.css("BusinessObject[@Name=MySubclass] Field[@Name=First]").first
        last_name = obj.dom.css("BusinessObject[@Name=MySubclass] Field[@Name=Last]").first
        first_name.content.should == "Eric"
        last_name.content.should == "Idle"
      end

      it "raises Cherby::BadFormat if XML is missing FieldList" do
        xml = %Q{
          <BusinessObject Name="MySubclass">
            <Whatever/>
          </BusinessObject>
        }
        lambda do
          @obj = MySubclass.new(xml)
        end.should raise_error(
          Cherby::BadFormat, /missing 'BusinessObject > FieldList'/)
      end

      it "raises Cherby::BadFormat if XML is missing BusinessObject" do
        xml = %Q{
          <Whatever Name="MySubclass"/>
        }
        lambda do
          @obj = MySubclass.new(xml)
        end.should raise_error(
          Cherby::BadFormat, /missing 'BusinessObject'/)
      end
    end #initialize

    describe "#check_dom_format!" do
      it "TODO"
    end #check_dom_format!

    describe "#[]" do
      it "returns the value in the named field" do
        obj = MySubclass.create({'First' => 'Eric', 'Last' => 'Idle'})
        obj['First'].should == 'Eric'
        obj['Last'].should == 'Idle'
      end

      it "returns nil if the field doesn't exist" do
        obj = MySubclass.create({'First' => 'Eric', 'Last' => 'Idle'})
        obj['Middle'].should be_nil
      end
    end #[]

    describe "#[]=" do
      it "puts a value in the named field" do
        obj = MySubclass.create({'First' => 'Eric', 'Last' => 'Idle'})
        obj['First'] = 'Terry'
        obj['Last'] = 'Jones'
        obj['First'].should == 'Terry'
        obj['Last'].should == 'Jones'
      end

      it "creates a new field if it doesn't exist" do
        obj = MySubclass.create({'First' => 'Eric', 'Last' => 'Idle'})
        obj['Middle'] = 'Something'
        obj['Middle'].should == 'Something'
      end
    end #[]=

    describe "#modified" do
      it "returns the parsed LastModDateTime if it's a valid date/time string" do
        # Parse the string version of now in order to truncate extra precision
        # (otherwise the date won't compare equal later)
        now = DateTime.parse(DateTime.now.to_s)

        obj = MySubclass.create({'LastModDateTime' => now})
        obj.modified.should == now
      end

      it "adjusts by default_tz_offset if LastModDateTime does not include an offset" do
        # Current time, without timezone offset
        now_str = DateTime.now.strftime('%Y-%m-%dT%H:%M:%S')
        now = DateTime.parse(now_str)

        obj = MySubclass.create({'LastModDateTime' => now_str})
        # Test a bunch of different timezone offsets
        [-7, -5, -2, 0, 1, 3, 4].each do |offset|
          obj.modified(offset).should == now - Rational(offset, 24)
        end
      end

      it "raises Cherby::BadFormat if LastModDateTime value is invalid" do
        obj = MySubclass.create({'LastModDateTime' => 'bogus'})
        lambda do
          obj.modified
        end.should raise_error(Cherby::BadFormat, /Cannot parse LastModDateTime: 'bogus'/)
      end

      it "raises Cherby::MissingData if LastModDateTime is empty" do
        xml = %Q{
          <BusinessObject Name="MySubclass">
            <FieldList>
            </FieldList>
          </BusinessObject>
        }
        obj = MySubclass.new(xml)
        lambda do
          obj.modified
        end.should raise_error(RuntimeError, /missing LastModDateTime/)
      end
    end #modified

    describe "#mod_s" do
      it "TODO"
    end #mod_s

    describe "#newer_than?" do
      before(:each) do
        @now = DateTime.now
        @older = MySubclass.create({'LastModDateTime' => (@now - 1)})
        @newer = MySubclass.create({'LastModDateTime' => @now})
      end

      it "true when this one was modified more recently than another" do
        @newer.newer_than?(@older).should be_true
      end

      it "false when this one was modified less recently than another" do
        @older.newer_than?(@newer).should be_false
      end
    end #newer_than?

    describe "#to_xml" do
      it "TODO"
    end #to_xml

    describe "#get_field_node" do
      before(:each) do
        xml = %Q{
          <BusinessObject Name="MySubclass">
            <FieldList>
              <Field Name="First">Eric</Field>
              <Field Name="Last">Idle</Field>
            </FieldList>
          </BusinessObject>
        }
        @obj = MySubclass.new(xml)
      end

      it "checks the DOM format" do
        @obj.should_receive(:check_dom_format!).and_return(true)
        @obj.get_field_node('First')
      end

      it "returns the Field having the given Name" do
        first_node = @obj.get_field_node('First')
        first_node.should be_a(Nokogiri::XML::Node)
        first_node.attr('Name').should == 'First'
        first_node.inner_html.should == 'Eric'
      end

      it "returns nil if the field doesn't exist" do
        middle_node = @obj.get_field_node('Middle')
        middle_node.should be_nil
      end
    end #get_field_node

    describe "#get_or_create_field_node" do
      before(:each) do
        xml = %Q{
          <BusinessObject Name="MySubclass">
            <FieldList>
              <Field Name="First">Eric</Field>
              <Field Name="Last">Idle</Field>
            </FieldList>
          </BusinessObject>
        }
        @obj = MySubclass.new(xml)
      end

      it "checks the DOM format" do
        @obj.should_receive(:check_dom_format!).and_return(true)
        @obj.get_or_create_field_node('First')
      end

      it "returns the Field having the given Name" do
        first_node = @obj.get_or_create_field_node('First')
        first_node.should be_a(Nokogiri::XML::Node)
        first_node.attr('Name').should == 'First'
        first_node.inner_html.should == 'Eric'
      end

      it "creates a new Field if it doesn't exist" do
        middle_node = @obj.get_or_create_field_node('Middle')
        middle_node.should be_a(Nokogiri::XML::Node)
        middle_node.attr('Name').should == 'Middle'
        middle_node.inner_html.should == ''
      end
    end #get_or_create_field_node

    describe "#field_values" do
      before(:each) do
        xml = %Q{
          <BusinessObject Name="MySubclass">
            <FieldList>
              <Field Name="First">Eric</Field>
              <Field Name="Last">Pierce</Field>
            </FieldList>
            <Relationship Name="Other fields">
              <FieldList>
                <Field Name="Middle">Matthew</Field>
              </FieldList>
            </Relationship>
          </BusinessObject>
        }
        @obj = MySubclass.new(xml)
      end

      it "includes fields inside the main FieldList element only" do
        @obj.field_values.should include('First')
        @obj.field_values.should include('Last')
        @obj.field_values.should_not include('Middle')
      end

      it "hashes field names to their values" do
        @obj.field_values['First'].should == 'Eric'
        @obj.field_values['Last'].should == 'Pierce'
      end
    end

    describe "#copy_fields_from" do
      before(:each) do
        xml = %Q{
          <BusinessObject Name="MySubclass">
            <FieldList>
              <Field Name="Status">Original Status</Field>
              <Field Name="Description">Original Description</Field>
              <Field Name="Comment">Original Comment</Field>
            </FieldList>
          </BusinessObject>
        }
        @obj1 = MySubclass.new(xml)
        @obj2 = MySubclass.new(xml)
      end

      it "copies fields from another BusinessObject" do
        @obj2['Status'] = 'Modified Status'
        @obj2['Description'] = 'Modified Description'

        @obj1.copy_fields_from(@obj2, 'Status', 'Description')
        @obj1['Status'].should == 'Modified Status'
        @obj1['Description'].should == 'Modified Description'
        @obj1['Comment'].should == 'Original Comment'
      end
    end
  end # Instance methods
end # Cherby::BusinessObject

