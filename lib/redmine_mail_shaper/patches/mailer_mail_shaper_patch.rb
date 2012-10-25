require_dependency 'mailer'


module RedmineMailShaper
  module Patches
    module MailerMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode

          def self.mail_shaper_deliver_issue_edit(journal)
            if journal.details.select{|k| k.property == 'time_entry'}.blank?
              deliver_issue_edit(journal)
            else
              recipients_can, recipients_can_not = journal.issue.recipients_can_view_time_entries
              watchers_can, watchers_can_not = journal.issue.watcher_recipients_can_view_time_entries

              deliver_mail_shaper_issue_edit(journal, recipients_can, watchers_can, true)
              deliver_mail_shaper_issue_edit(journal, recipients_can_not, watchers_can_not, false)
            end
          end

        end
      end

      module InstanceMethods

        # Builds a tmail object used to email recipients of the edited issue.
        def mail_shaper_issue_edit(journal, ms_recipients, ms_watchers, can_view_time_entries)
          issue = journal.journalized.reload
          redmine_headers 'Project' => issue.project.identifier,
                          'Issue-Id' => issue.id,
                          'Issue-Author' => issue.author.login
          redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
          message_id journal
          references issue
          @author = journal.user
          recipients ms_recipients
          # Watchers in cc
          cc(ms_watchers - @recipients)
          s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
          s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
          s << issue.subject
          subject s
          body :issue => issue,
               :journal => journal,
               :can_view_time_entries => can_view_time_entries,
               :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")

          render_multipart('issue_edit', body)
        end

      end
    end
  end
end

