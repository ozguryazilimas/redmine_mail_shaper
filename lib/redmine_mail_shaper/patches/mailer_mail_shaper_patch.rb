require_dependency 'mailer'


module RedmineMailShaper
  module Patches
    module MailerMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode

          def self.mail_shaper_deliver_issue_edit(journal)
            if journal.details.select{|k| (k.property == 'time_entry') || (k.prop_key == 'estimated_hours')}.blank?
              self.deliver_issue_edit(journal)
            else
              recipient_users = journal.recipients_can_view_time_entries
              watcher_users = journal.watcher_recipients_can_view_time_entries

              # if there is only time_entry on issue/edit change make sure we do not send blank
              # emails to recipients who should not see time entries
              if journal.notes.blank?
                jd_all = journal.details
                jd_time_entry = jd_all.select{|k| k.property == 'time_entry'}
                jd_estimated_time = jd_all.select{|k| k.prop_key == 'estimated_hours'}

                # if we have anything other than time entry or estimated time, send the mail
                # if we only have time entry, skip the ones can not see time entry
                # if we only have estimated time, skip the ones can not see estimated time
                if (jd_all - jd_time_entry - jd_estimated_time).count == 0
                  if (jd_all - jd_time_entry).count == 0
                    recipient_users[:can_not_time_entry][:can_estimated_time] = []
                    recipient_users[:can_not_time_entry][:can_not_estimated_time] = []

                    watcher_users[:can_not_time_entry][:can_estimated_time] = []
                    watcher_users[:can_not_time_entry][:can_not_estimated_time] = []
                  end

                  if (jd_all - jd_estimated_time).count == 0
                    recipient_users[:can_time_entry][:can_not_estimated_time] = []
                    recipient_users[:can_not_time_entry][:can_not_estimated_time] = []

                    watcher_users[:can_time_entry][:can_not_estimated_time] = []
                    watcher_users[:can_not_time_entry][:can_not_estimated_time] = []
                  end
                end
              end

              recipient_users.each do |time_entry_key, subhash|
                subhash.each do |estimated_time_key, val|
                  mail_shaper_issue_edit(
                    journal,
                    recipient_users[time_entry_key][estimated_time_key],
                    watcher_users[time_entry_key][estimated_time_key],
                    time_entry_key == :can_time_entry,
                    estimated_time_key == :can_estimated_time
                  ).deliver
                end
              end
            end
          end

          # default issue_edit with updated headers
          def issue_edit(journal, to_users, cc_users)
            issue = journal.journalized.reload
            redmine_headers 'Project' => issue.project.identifier,
                            'Issue-Id' => issue.id,
                            'Issue-Author' => issue.author.login
            redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
            redmine_headers 'Issue-Edit-Has-Note' => (journal.notes.blank? ? 'No' : 'Yes')
            message_id journal
            references issue
            @author = journal.user
            s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
            s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
            s << issue.subject
            @issue = issue
            @users = to_users + cc_users
            @journal = journal
            @journal_details = journal.visible_details(@users.first)
            @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
            mail :to => to_users.map(&:mail),
              :cc => cc_users.map(&:mail),
              :subject => s
          end
        end
      end

      module InstanceMethods

        # Builds a tmail object used to email recipients of the edited issue. Called only on time_entry changes
        def mail_shaper_issue_edit(journal, ms_recipients, ms_watchers, can_view_time_entries, can_view_estimated_time)
          issue = journal.journalized.reload
          redmine_headers 'Project' => issue.project.identifier,
                          'Issue-Id' => issue.id,
                          'Issue-Author' => issue.author.login
          redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
          redmine_headers 'Issue-Edit-Has-Note' => (journal.notes.blank? ? 'No' : 'Yes')
          message_id journal
          references issue
          @author = journal.user
          recipients = ms_recipients
          @users = recipients
          # Watchers in cc
          cc = ms_watchers - recipients
          s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
          s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
          s << issue.subject
          @issue = issue
          @journal = journal
          @journal_details = journal.visible_details(User.where(:mail => @users.first).first)
          @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
          @can_view_time_entries = can_view_time_entries
          @can_view_estimated_time = can_view_estimated_time
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

