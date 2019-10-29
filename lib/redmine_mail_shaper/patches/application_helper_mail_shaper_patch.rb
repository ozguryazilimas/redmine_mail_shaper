require_dependency 'application_helper'


module RedmineMailShaper
  module Patches
    module ApplicationHelperMailShaperPatch
      def self.included(base) # :nodoc:
        base.class_eval do

          # need this to be accessible from issues, time_entries, timelogs, mailer etc.
          def rms_time_entry_as_issue_journal(time_entry, for_type, entry_attrs, no_html = false)
            time_entry_change = l("journal_entry_time_entry_#{for_type}")

            link_value = l(:label_f_hour_plural, :value => entry_attrs['hours'])
            link_value += no_html ? " #{entry_attrs['activity_name']}" :
                                    " <i>#{entry_attrs['activity_name']}</i>".html_safe
            link_value += entry_attrs['comments'].html_safe

            if for_type == 'update'
              link_value_was = l(:label_f_hour_plural, :value => entry_attrs['hours_was'])
              link_value_was += no_html ? " #{entry_attrs['activity_name_was']}" :
                                          " <i>#{entry_attrs['activity_name_was']}</i>".html_safe
              link_value_was += entry_attrs['comments_was']

              link_value = "#{link_value_was} -> #{link_value}".html_safe
            end

            if time_entry
              time_entry_link = no_html ? link_value :
                                link_to(link_value.html_safe,
                                  :controller => 'timelog',
                                  :action => 'edit',
                                  :issue_id => time_entry.issue_id,
                                  :id => time_entry.id
                                )
            else
              time_entry_link = no_html ? "#{link_value} #{l(:label_deleted)}" :
                                         "<strike><i>#{link_value} #{l(:label_deleted)}</i></strike>".html_safe
            end

            rval = no_html ? "#{time_entry_change} #{time_entry_link}" :
                             "<strong>#{time_entry_change}</strong> #{time_entry_link}".html_safe
            rval
          end

        end
      end

    end
  end
end

