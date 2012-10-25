require_dependency 'time_entry'


module RedmineMailShaper
  module Patches
    module TimeEntryMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
        end
      end

      module InstanceMethods

        def after_create
          create_journal('create')
        end

        def after_update
          create_journal('update')
        end

        def after_destroy
          create_journal('delete')
        end

        def create_journal_entry
          create_journal('create', true)
        end

        private

        def create_journal(for_type, force_save=false)
          journal = issue.current_journal || issue.init_journal(User.current)

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
            issue.save!
          end
        end

      end
    end
  end
end

