require_relative 'spec_helper'
require 'cherby/incident'
require 'cherby/task'
require 'cherby/journal_note'

module Cherby
  describe Incident do
    before(:each) do
      @incident_xml = File.read(File.join(DATA_DIR, 'incident.xml'))
      @incident = Incident.new(@incident_xml)
    end

    context "Instance  methods" do
      describe "#id" do
        it "returns the IncidentID" do
          @incident.id.should == '51949'
          @incident.id.should == @incident['IncidentID']
        end
      end #id

      describe "#exists?" do
        it "true when IncidentID is set" do
          @incident.exists?.should be_true
        end

        it "false when IncidentID is nil" do
          @incident['IncidentID'] = nil
          @incident.exists?.should be_false
        end
      end #exists?

      describe "#tasks" do
        it "returns an array of Task instances" do
          @incident.tasks.count.should == 5
          @incident.tasks.each do |task|
            task.should be_a(Task)
          end
        end
      end #tasks

      describe "#journal_notes" do
        it "returns an array of JournalNote instances" do
          @incident.journal_notes.count.should == 4
          @incident.journal_notes.each do |journal_note|
            journal_note.should be_a(JournalNote)
          end
        end
      end #journal_notes

      describe "#add_task" do
        it "adds to RelationshipList children" do
          before = @incident.dom.css("RelationshipList").first.children
          @incident.add_task("The description", "The notes")
          # Ensure that a new Relationship was appended
          after = @incident.dom.css("RelationshipList").first.children
          # FIXME: Test this better
          # Extra "\n" children may be added for some unknown reason; just check that
          # there are more children now than there were before
          before.count.should be < after.count
        end
      end #add_task

      describe "#add_journal_note" do
        it "adds a JournalNote" do
          journal_note = JournalNote.create({
            'Details' => 'New note on incident',
          })
          @incident.add_journal_note(journal_note)
          last_journal_note = @incident.journal_notes.last
          last_journal_note['Details'].should == 'New note on incident'
        end
      end #add_journal_note
    end # Instance methods

    context "Inherited instance methods" do
      it "#to_xml" do
        @incident.to_xml.should == @incident_xml
      end

      it "#field_values" do
        fields = @incident.field_values
        fields['IncidentID'].should == '51949'
        fields['JIRAID'].should == 'TST-72'
        fields['Environment'].should == 'PRD'
        fields['Description'].should == "Test new cherwell ID field"
      end
    end

  end # describe Incident
end # module Cherby

