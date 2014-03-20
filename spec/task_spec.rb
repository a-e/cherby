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

      describe "#differs_from?" do
        it "false when compared with itself" do
          task = Task.new(@task_xml)
          task.differs_from?(task).should be_false
        end

        it "false when compared with a task with identical fields" do
          task1 = Task.new(@task_xml)
          task2 = Task.new(@task_xml)
          task2.differs_from?(task1).should be_false
        end

        it "true if certain fields are different" do
          task1 = Task.new(@task_xml)
          task2 = Task.new(@task_xml)
          task1['Status'] = 'New'
          task2['Status'] = 'Assigned'
          task1.differs_from?(task2).should be_true
          task2.differs_from?(task1).should be_true
        end
      end #differs_from?

      describe "#update_from" do
        it "modifies Status and ResolutionCode" do
          task1 = Task.new(@task_xml)
          task2 = Task.new(@task_xml)

          task1['Status'] = 'Resolved'
          task1['ResolutionCode'] = 'Completed'

          task2.update_from(task1)
          task2['Status'].should == 'Resolved'
          task2['ResolutionCode'].should == 'Completed'
        end
      end #update_from

      describe "#add_journal_note" do
        it "adds a note to the Task" do
          task = Task.new(@task_xml)
          journal_note = JournalNote.create({
            :details => 'New note on task',
            :last_mod_date_time => DateTime.now,
          })
          task.add_journal_note(journal_note)
          task['CompletionDetails'].should =~ /New note on task/
        end
      end #add_journal_note

    end # Instance methods

  end # describe Task
end # module Cherby
