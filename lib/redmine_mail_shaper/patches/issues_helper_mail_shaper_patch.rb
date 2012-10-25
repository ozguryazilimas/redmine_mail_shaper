require_dependency 'issues_helper'


module RedmineMailShaper
  module Patches
    module IssuesHelperMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
          alias_method_chain :details_to_strings, :mail_shaper
        end
      end

      module InstanceMethods

        def parent_issue_subject(issue)
          if Setting[:plugin_redmine_mail_shaper][:issue_show_parent_subject] and issue.parent_issue_id
            Issue.find_by_id(issue.parent_issue_id).subject
          else
            nil
          end
        end

        def details_to_strings_with_mail_shaper(details, no_html=false, options={})
          detail = details.first

          if detail && detail.property == 'time_entry'
            current_project = @project || detail.journal.project

            if User.current.allowed_to?(:view_time_entries, current_project)
              time_entry = TimeEntry.find_by_id(detail.prop_key)
              time_entry_change = l("journal_entry_time_entry_#{detail.value}")

              entry_attrs = YAML.load(detail.old_value)

              link_value = l(:label_f_hour_plural, :value => entry_attrs['hours'])
              link_value += no_html ? " #{entry_attrs['activity_name']}" :
                                      " <i>#{entry_attrs['activity_name']}</i>"
              link_value += entry_attrs['comments']

              if detail.value == 'update'
                link_value_was = l(:label_f_hour_plural, :value => entry_attrs['hours_was'])
                link_value_was += no_html ? " #{entry_attrs['activity_name_was']}" :
                                            " <i>#{entry_attrs['activity_name_was']}</i>"
                link_value_was += entry_attrs['comments_was']

                link_value = "#{link_value_was} -> #{link_value}"
              end

              if time_entry
                time_entry_link = no_html ? link_value :
                                  link_to(link_value,
                                    :controller => 'timelog',
                                    :action => 'edit',
                                    :issue_id => time_entry.issue_id,
                                    :id => time_entry.id
                                  )
              else
                time_entry_link = no_html ? "#{link_value} #{l(:label_deleted)}" :
                                           "<strike><i>#{link_value} #{l(:label_deleted)}</i></strike>"
              end

              rval = no_html ? ["#{time_entry_change} #{time_entry_link}"] :
                               ["<strong>#{time_entry_change}</strong> #{time_entry_link}"]
            end
          else
            # TODO: remove it when we switch to ruby 1.9.x
            rval = nil
          end

          all_details = details_to_strings_without_mail_shaper(details, no_html, options)

          # Time entry is not properly parsed by redmine so it leaves a nil
          all_details.delete(nil)
          all_details << rval unless rval.blank?

          all_details
        end

      end
    end
  end
end

