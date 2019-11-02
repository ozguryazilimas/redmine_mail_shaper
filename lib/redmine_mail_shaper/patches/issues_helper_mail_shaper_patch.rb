require_dependency 'issues_helper'


module RedmineMailShaper
  module Patches
    module IssuesHelperMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods

        def details_to_strings(details, no_html=false, options={})
          detail = details.first
          rval = nil

          if detail && detail.property == 'time_entry'
            current_project = @project || detail.journal.project

            if User.current.rms_can_view_time_entries(current_project)
              time_entry = TimeEntry.find_by_id(detail.prop_key)
              entry_attrs = YAML.load(detail.old_value)
              rval = rms_time_entry_as_issue_journal(time_entry, detail.value, entry_attrs, no_html)
            end
          end

          all_details = super

          # Time entry is not properly parsed by redmine so it leaves a nil
          all_details.delete(nil)
          all_details << rval.html_safe unless rval.blank?

          all_details
        end

        def email_issue_attributes(issue, user, html)
          rms_items = []

          parent_subject = issue.rms_parent_issue_subject
          if parent_subject.present?
            if html
              rms_items << content_tag('strong', "#{l(:field_parent_issue)}: ") + (h parent_subject)
            else
              rms_items << "#{l(:field_parent_issue)}: #{h parent_subject}"
            end
          end

          rms_items += super

          if user.rms_can_view_time_entries(issue.project)
            spent_hours_value = issue.total_spent_hours > 0 ? l(:label_f_hour_plural, :value => "%.2f" % issue.total_spent_hours) : '-'

            if html
              rms_items << content_tag('strong', "#{l(:label_spent_time)}: ") + spent_hours_value
            else
              rms_items << "#{l(:label_spent_time)}: #{spent_hours_value}"
            end
          end

          rms_items
        end

      end
    end
  end
end

IssuesController.helper(RedmineMailShaper::Patches::IssuesHelperMailShaperPatch)
Mailer.helper(RedmineMailShaper::Patches::IssuesHelperMailShaperPatch)


