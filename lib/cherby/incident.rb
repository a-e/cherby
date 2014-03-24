require 'date'
require 'mustache'
require 'cherby/business_object'
require 'cherby/task'
require 'cherby/journal_note'

module Cherby
  # Wrapper for Cherwell incident objects.
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

    # Mark this incident as complete by filling in relevant fields.
    # FIXME: Parameterize these, instead of assuming Jira relationship.
    #
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

    # Return Task instances for all tasks associated with this Incident
    #
    # @return [Array<Task>]
    #
    def tasks
      @tasks ||= @dom.css("BusinessObject[@Name=Task]").map do |element|
        Task.new(element.to_xml)
      end
    end

    # Return all journal notes associated with this Incident.
    #
    # @return [Array<JournalNote>]
    #
    def journal_notes
      css = "Relationship[@Name='Incident has Notes']" +
            " BusinessObject[@Name=JournalNote]"
      return @dom.css(css).map do |element|
        JournalNote.new(element.to_xml)
      end
    end

    # Add a new Task to this incident.
    def add_task(task_description = "", task_notes = "", owned_by = "")
      # Bail out if this incident doesn't actually exist
      return nil if !exists?
      task = Task.create({
        'ParentPublicID' => self['IncidentID'],
        'ParentTypeName' => 'Incident',
        'TaskType' => 'Action',
        'TaskDescription' => task_description,
        'Notes' => task_notes,
        'OwnedBy' => owned_by,
      })
      rel_node = Nokogiri::XML::Node.new('Relationship', @dom)
      rel_node['Name'] = 'Incident Has Tasks'
      rel_node['TargetObjectName'] = 'Task'
      rel_node['Type'] = 'Owns'
      rel_node.inner_html = task.dom.css('BusinessObject').to_xml
      @dom.at_css('RelationshipList').add_child(rel_node)
    end

    # Add a new JournalNote to this incident.
    #
    # @param [JournalNote] journal_note
    #   The note to add to the incident
    #
    def add_journal_note(journal_note)
      return nil if !exists?
      rel_node = Nokogiri::XML::Node.new('Relationship', @dom)
      rel_node['Name'] = 'Incident has Notes'
      rel_node['TargetObjectName'] = 'JournalNote'
      rel_node['Type'] = 'Owns'
      rel_node.inner_html = journal_note.dom.css('BusinessObject').to_xml
      @dom.at_css('RelationshipList').add_child(rel_node)
    end

    # Return True if this Incident has important fields differing from the
    # given Incident.
    #
    # @param [Incident] incident
    #   The Incident to compare this one to.
    #
    # @return [Boolean]
    #   `true` if the incidents differn `false` otherwise.
    #
    def differs_from?(incident)
      return true if self['Status'] != incident['Status']
      return true if self['JIRAID'] != incident['JIRAID']
      return false
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

