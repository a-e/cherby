require 'date'
require 'cherby/business_object'

module Cherby
  class JournalNote < BusinessObject
    @object_name = 'JournalNote'
    @default_values = {
      :details => "",
    }
  end
end

