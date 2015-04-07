require_dependency 'time_entry'


module RedmineMailShaper
  module Patches
    module TimeEntryMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
          after_create :mail_shaper_after_create
          after_update :mail_shaper_after_update
          after_destroy :mail_shaper_after_destroy
        end
      end

      module InstanceMethods

        def mail_shaper_after_create
          create_journal('create')
        end

        def mail_shaper_after_update
          create_journal('update')
        end

        def mail_shaper_after_destroy
          create_journal('delete')
        end

        def create_journal_entry
          create_journal('create', true)
        end


        private


        def create_journal(for_type, force_save=false)
          should_send_email = RedmineMailShaper.settings[:time_entry_send_email]
          should_create_journal = RedmineMailShaper.settings[:time_entry_create_journal]

          if issue
            if should_create_journal

              # add entry to old issue if issue id of an entry has changed and add the new entry
              # to new issue as if it is a new one
              if for_type == 'update' && issue_id_was && issue_id_was != issue_id
                create_journal_for_issue('delete', force_save && should_send_email, issue_id_was)
                create_journal_for_issue('create', should_send_email)
              else
                create_journal_for_issue(for_type, force_save && should_send_email)
              end
            elsif should_send_email
              send_email_for_entry(for_type, force_save)
            end
          else
            if should_send_email
              send_email_for_entry(for_type, force_save)
            end
          end
        end

        def send_email_for_entry(for_type, force_save)
          # We do not suppress email here since that setting is for issue changes only
          notified = project.notified_users.select {|k| k.allowed_to?(:view_time_entries, project)}
          notified.uniq!
          activity_old = TimeEntryActivity.find(activity_id_was).name_was rescue ''

          Mailer.time_entry_edit(self,
                                 for_type,
                                 notified.collect(&:mail),
                                 activity_old
          ).deliver
        end

        def create_journal_for_issue(for_type, force_save, force_issue_id = false)
          # try really hard not to create entries for anonymous users
          init_journal_user = User.current

          if (init_journal_user == User.anonymous) && user
            init_journal_user = user
          end

          if force_issue_id
            target_issue = Issue.find(force_issue_id)
          else
            target_issue = issue
          end

          journal = target_issue.current_journal || target_issue.init_journal(init_journal_user)

          # changes in associations are not considered as dirty record for self
          # so we have to fetch the data by hand
          activity_old = TimeEntryActivity.find(activity_id_was).name rescue ''
          activity_new = TimeEntryActivity.find(activity_id).name rescue ''

          # keep obj values as hash in db to allow conditional formatting on helper
          obj_old_value = {
            'hours_was' => hours_was,
            'hours' => hours,
            'comments_was' => comments_was.blank? ? "" : " (#{comments_was})",
            'comments' => comments.blank? ? "" : " (#{comments})",
            'activity_name_was' => activity_old,
            'activity_name' => activity_new
          }


          journal.details << JournalDetail.new(:property => 'time_entry',
                                               :prop_key => id,
                                               :value => for_type,
                                               :old_value => obj_old_value.to_yaml)

          # journal.save does not trigger change for issue.updated_on
          # but if we are creating a time_spent then we definitely know that there will be
          # an issue.save! . We skip saving journal and issue on create, because
          # the minute we save mail sender is triggered, and we may loose other journal
          # details if they are not processed yet.

          unless ((for_type == 'create') and !force_save)
            journal.save!
            target_issue.save!
          end
        end

      end
    end
  end
end

