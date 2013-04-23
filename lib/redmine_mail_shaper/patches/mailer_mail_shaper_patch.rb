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
              issue_edit(journal).deliver
            else
              recipients_can, recipients_can_not = journal.recipients_can_view_time_entries
              watchers_can, watchers_can_not = journal.watcher_recipients_can_view_time_entries

              mail_shaper_issue_edit(journal, recipients_can, watchers_can, true).deliver
              mail_shaper_issue_edit(journal, recipients_can_not, watchers_can_not, false).deliver
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
          recipients = ms_recipients
          # Watchers in cc
          cc = ms_watchers - recipients
          s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
          s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
          s << issue.subject
          @issue = issue
          @journal = journal
          @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
          @can_view_time_entries = can_view_time_entries
          mail :to => recipients,
            :cc => cc,
            :subject => s
        end

        def time_entry_edit(time_entry, for_type, notified, activity_name_was)
          redmine_headers 'Project' => time_entry.project.identifier
          @author = time_entry.user
          message_id time_entry

          @time_entry = time_entry
          @for_type = for_type
          @time_entry_url = url_for(:controller => 'timelog', :action => 'edit', :id => time_entry.id)
          @activity_name = time_entry.activity.name
          @activity_name_was = activity_name_was
          @comments = time_entry.comments
          @comments_was = time_entry.comments_was
          @hours = time_entry.hours
          @hours_was = time_entry.hours_was

          mail :to => notified,
            :subject => "[#{time_entry.project.name}] " + l("journal_entry_time_entry_#{for_type}")
        end

      end
    end
  end
end

