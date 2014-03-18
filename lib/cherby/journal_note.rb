require 'date'
require 'cherby/business_object'

module Cherby
  class JournalNote < BusinessObject
    @object_name = 'JournalNote'
    @template = 'journal_note'
    @default_values = {
      :details => "",
    }

    # Return a new JournalNote populated with data from the given Jira comment.
    # FIXME: Implement this in jira2cherwell
    #def self.from_jira(jira_comment)
      #jira_data = j2c_comment(jira_comment)
      #return self.create(jira_data)
    #end

  end
end

