require 'date'
require 'cherby/business_object'

module Cherby
  # Wrapper for Cherwell task objects.
  class Task < BusinessObject
    # Return this task's public ID.
    def id
      self['TaskID']
    end

    # Return true if this task exists in Cherwell.
    def exists?
      return !id.to_s.empty?
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

