require_dependency 'issues_helper'


module RedmineMailShaper
  module Patches
    module IssuesHelperMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :details_to_strings, :mail_shaper
        end
      end

      module InstanceMethods

        def details_to_strings_with_mail_shaper(details, no_html=false, options={})
          detail = details.first

          if detail && detail.property == 'time_entry'
            current_project = @project || detail.journal.project

            if options[:should_force_time_entry_view] || User.current.allowed_to?(:view_time_entries, current_project)
              time_entry = TimeEntry.find_by_id(detail.prop_key)
              entry_attrs = YAML.load(detail.old_value)
              rval = rms_time_entry_as_issue_journal(time_entry, detail.value, entry_attrs, no_html)
            end
          else
            # TODO: remove it when we switch to ruby 1.9.x
            rval = nil
          end

          all_details = details_to_strings_without_mail_shaper(details, no_html, options)

          # Time entry is not properly parsed by redmine so it leaves a nil
          all_details.delete(nil)
          all_details << rval.html_safe unless rval.blank?

          all_details
        end

      end
    end
  end
end

