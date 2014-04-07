require_relative 'spec_helper'
require 'cherby/task'
require 'cherby/journal_note'

module Cherby
  describe Task do
    context "Instance methods" do
      before(:each) do
        @task_xml = File.read(File.join(DATA_DIR, 'task.xml'))
      end

      describe "#id" do
        it "returns the value from the TaskID field" do
          task = Task.new(@task_xml)
          task['TaskID'] = '9876'
          task.id.should == '9876'
        end
      end #id

      describe "#exists?" do
        it "true if task ID is non-nil" do
          task = Task.new(@task_xml)
          task['TaskID'] = '9876'
          task.exists?.should be_true
        end

        it "false if task ID is nil" do
          task = Task.new(@task_xml)
          task['TaskID'] = nil
          task.exists?.should be_false
        end

        it "false if task ID is empty string" do
          task = Task.new(@task_xml)
          task['TaskID'] = ''
          task.exists?.should be_false
        end
      end #exists?

      describe "#add_journal_note" do
        it "adds a note to the Task" do
          task = Task.new(@task_xml)
          journal_note = JournalNote.create({
            'Details' => 'New note on task',
            'LastModDateTime' => DateTime.now,
          })
          task.add_journal_note(journal_note)
          task['CompletionDetails'].should =~ /New note on task/
        end
      end #add_journal_note

    end # Instance methods

  end # describe Task
end # module Cherby
