require 'date'
require 'mustache'
require 'cherby/business_object'
require 'cherby/task'
require 'cherby/journal_note'
require 'cherby/consts'

module Cherby
  class Incident < BusinessObject
    @object_name = 'Incident'
    @template = 'incident'
    @default_values = {
      :service            => "Auto Generated",
      :service_group      => "Auto Generated",
      :category           => "Auto Generated",
      :sub_category       => "JIRA",
      :impact             => "Inconvenience",
      :urgency            => "Medium",
      :priority           => "3",
    }

    def id
      self['IncidentID']
    end

    # Return true if this incident already exists in Cherwell
    # (that is, its id is a nonempty string of digits)
    def exists?
      return id.to_s =~ /\d+/
    end

    def complete!(comments = "Closed in Jira => automated close.")
      self["CloseDescription"] = comments
      self["LastModDateTime"] = DateTime.now.to_s
      self["Stat_NumberOfTouches"] = self["Stat_NumberOfTouches"].to_i + 1
      #self["PhaseInvestigateStatus"] = "Complete"
      self["PhaseResolveStatus"] = "Complete"
      #self["PhaseCloseStatus"] = "Complete"
      self["ClosureCode"] = "Completed"
      self["CMDBUpdate"] = "No"
      self["BusinessService"] = "Not Applicable"
      self["RequestType"] = "Not Applicable"
      self["SubCategory"] = "JIRA"
      self["SubcategoryNonHR"] = "JIRA"
    end

    def reopen!(comments = nil)
    end

    # Return Task instances for all tasks associated with this Incident
    def tasks
      @tasks ||= @dom.css("BusinessObject[@Name=Task]").map do |element|
        Task.new(element.to_xml)
      end
    end

    # Return JournalNote instances for all notes associated with this Incident
    def journal_notes
      css = "Relationship[@Name='Incident has Notes']" +
            " BusinessObject[@Name=JournalNote]"
      @notes ||= @dom.css(css).map do |element|
        JournalNote.new(element.to_xml)
      end
    end

    # Add a new Task to this incident.
    def add_task(task_description = "", task_notes = "", owned_by = "")
      # Bail out if this incident doesn't actually exist
      return nil if !exists?
      task = Task.create({
        :parent_public_id => self['IncidentID'],
        :parent_type_name => 'Incident',
        :task_type => 'Action',
        :task_description => task_description,
        :notes => task_notes,
        :owned_by => owned_by,
      })
      relationship_xml = Mustache.render_file('task_relationship',
        {:task_business_object => task.dom.css('BusinessObject').to_xml})
      @dom.css('RelationshipList').first.add_child(relationship_xml)
    end

    # Add a new JournalNote to this incident.
    def add_journal_note(journal_note)
      return nil if !exists?
      relationship_xml = Mustache.render_file('journal_note_relationship',
        {:note_business_object => journal_note.dom.css('BusinessObject').to_xml})
      @dom.css('RelationshipList').first.add_child(relationship_xml)
    end

    # Return True if this Incident has important fields differing from the
    # given Incident.
    def differs_from?(incident)
      return true if self['Status'] != incident['Status']
      return true if self['JIRAID'] != incident['JIRAID']
      return false
    end

    # Update this Incident with important fields from the given Incident.
    def update_from(incident)
      self['Status'] = incident['Status']
      self['JIRAID'] = incident['JIRAID']
    end

    # DO NOT REMOVE: use the follow code for code-gen of Cherwell consts
=begin
    def extract_lines(css, l)
      lines = []
      @dom.css(css).each do |f|
        lines << "  #{('"' + f["Name"] + '"').ljust(l)} => \"#{f["IDREF"]}\""
      end
      lines
    end

    def extract
      puts "*"*80
      puts "{"
      puts extract_lines("BusinessObject[@Name=Incident] Field", 40).join(",\n")
      puts "}"
      puts "*"*80
      puts "{"
      extract_lines("BusinessObject[@Name=Task] Field", 24).join(",\n")
      puts "}"
      puts "*"*80
    end
=end

  end # class Incident
end # module Cherby

