require 'date'
require 'cherby/business_object'

module Cherby
  class JournalNote < BusinessObject
    @object_name = 'JournalNote'
    @template = 'journal_note'
    @default_values = {
      :details => "",
    }
  end
end

