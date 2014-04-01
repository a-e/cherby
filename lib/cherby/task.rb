require 'date'
require 'cherby/business_object'

module Cherby
  class Task < BusinessObject
    def id
      self['TaskID']
    end

    def exists?
      return !id.to_s.empty?
    end

    # Return True if this Task has important fields differing from the given Task.
    def differs_from?(task)
      return true if self['Status'] != task['Status']
      return false
    end

    # Add a JournalNote to this Task. Since Tasks cannot directly have JournalNotes
    # associated with them, this just appends the note's content to the Technician Notes
    # field (aka 'CompletionDetails') in the Task.
    def add_journal_note(journal_note)
      message = "\n============================\n" + \
        "Comment added #{journal_note.mod_s} by #{journal_note['CreatedBy']}: " + \
        journal_note['Details'].to_s + "\n\n"
      self['CompletionDetails'] = self['CompletionDetails'] + message
    end
  end
end # module Cherby

