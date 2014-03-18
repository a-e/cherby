require_relative 'spec_helper'
require 'cherby/business_object'

# Some BusinessObject subclasses to test with
class MySubclass < Cherby::BusinessObject
  @object_name = 'MySubclass'
  @template = 'test/simple'
  @default_values = {}
end

class MySubclassNoTemplate < Cherby::BusinessObject
  @object_name = 'MySubclassNoTemplate'
  @template = ''
  @default_values = {}
end

class MySubclassNoTemplateFile < Cherby::BusinessObject
  @object_name = 'MySubclassNoTemplateFile'
  @template = 'no_such_file'
  @default_values = {}
end

describe Cherby::BusinessObject do
  context "Class methods" do
    describe "#create" do
      it "sets options" do
        obj = MySubclass.create({:first_name => 'Eric', :last_name => 'Idle'})
        first_name = obj.dom.css("BusinessObject[@Name=MySubclass] Field[@Name=First]").first
        last_name = obj.dom.css("BusinessObject[@Name=MySubclass] Field[@Name=Last]").first
        first_name.content.should == "Eric"
        last_name.content.should == "Idle"
      end

      it "raises an exception when no template is provided" do
        lambda do
          MySubclassNoTemplate.create
        end.should raise_error(RuntimeError, /No template defined/)
      end

      it "raises an exception if the template file is nonexistent" do
        lambda do
          MySubclassNoTemplateFile.create
        end.should raise_error(Errno::ENOENT, /No such file/)
      end
    end #create

    describe "#parse_datetime" do
      it "with timezone offset" do
        bo = Cherby::BusinessObject
        dt = bo.parse_datetime("2012-02-09T09:42:13-05:00")
        dt.to_s.should == "2012-02-09T14:42:13+00:00"

        dt = bo.parse_datetime("2012-02-09T09:42:13.123-0500")
        dt.to_s.should == "2012-02-09T14:42:13+00:00"
      end

      it "without timezone offset" do
        bo = Cherby::BusinessObject
        dt = bo.parse_datetime("2012-02-09T09:42:13", -5)
        dt.to_s.should == "2012-02-09T14:42:13+00:00"
      end

      it "with invalid datetime string" do
        bo = Cherby::BusinessObject
        lambda do
          bo.parse_datetime("bogus-datetime")
        end.should raise_error(ArgumentError, /Could not parse/)
      end

    end #parse_datetime

  end # Class methods


  context "Instance methods" do
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

    end #initialize

    describe "#[]" do
      it "returns the value in the named field" do
        obj = MySubclass.create({:first_name => 'Eric', :last_name => 'Idle'})
        obj['First'].should == 'Eric'
        obj['Last'].should == 'Idle'
      end
    end #[]

    describe "#[]=" do
      it "puts a value in the named field" do
        obj = MySubclass.create({:first_name => 'Eric', :last_name => 'Idle'})
        obj['First'] = 'Terry'
        obj['Last'] = 'Jones'
        obj['First'].should == 'Terry'
        obj['Last'].should == 'Jones'
      end
    end #[]=

    describe "#modified" do
      it "BusinessObject with a valid LastModDateTime value" do
        # Parse the string version of now in order to truncate extra precision
        # (otherwise the date won't compare equal later)
        now = DateTime.parse(DateTime.now.to_s)

        obj = MySubclass.create({:last_mod_date_time => now})
        obj.modified.should == now
      end

      it "BusinessObject with an invalid LastModDateTime value" do
        obj = MySubclass.create({:last_mod_date_time => 'bogus'})
        lambda do
          obj.modified
        end.should raise_error(RuntimeError, /Cannot parse LastModDateTime: 'bogus'/)
      end

      it "BusinessObject without a LastModDateTime field" do
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
        @older = MySubclass.create({:last_mod_date_time => (@now - 1)})
        @newer = MySubclass.create({:last_mod_date_time => @now})
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
      it "TODO"
    end #get_field_node

    describe "#field_values" do
      it "returns a hash of field names and their values" do
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
        obj = MySubclass.new(xml)
        # Only fields inside the main FieldList should be included
        obj.field_values.should == {
          'First' => 'Eric',
          'Last' => 'Pierce',
        }
      end
    end
  end # Instance methods

end # Cherby::BusinessObject

