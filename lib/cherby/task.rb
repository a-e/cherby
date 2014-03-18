require 'date'
require 'cherby/business_object'

module Cherby
  class Task < BusinessObject
    @object_name = 'Task'
    @template = 'task'
    @default_values = {
      :status             => "New",
    }

    # Return a new Task populated with data from the given Jira sub-task.
    # FIXME: Implement this in jira2cherwell
    #def self.from_jira(jira_task)
      #jira_data = j2c_task(jira_task)
      #return self.create(jira_data)
    #end

    def id
      self['TaskID']
    end

    def exists?
      return !id.nil?
    end

    # Return True if this Task has important fields differing from the given Task.
    def differs_from?(task)
      return true if self['Status'] != task['Status']
      return false
    end

    # Update this Task with important fields from the given Task.
    def update_from(task)
      self['Status'] = task['Status']
      self['ResolutionCode'] = task['ResolutionCode']
    end

    # Add a JournalNote to this Task. Since Tasks cannot directly have JournalNotes
    # associated with them, this just appends the note's content to the Technician Notes
    # field (aka 'CompletionDetails') in the Task.
    def add_journal_note(journal_note)
      message = "\n============================\n" + \
        "Comment added #{journal_note.mod_s} by #{journal_note['CreatedBy']}: " + \
        journal_note['Details'] + "\n\n"
      self['CompletionDetails'] = self['CompletionDetails'] + message
    end
  end
end # module Cherby

