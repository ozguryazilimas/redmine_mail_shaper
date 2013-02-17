require_dependency 'journal_observer'


module RedmineMailShaper
  module Patches
    module JournalObserverMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
          alias_method_chain :after_create, :mail_shaper
        end
      end

      module InstanceMethods

        def after_create_with_mail_shaper(journal)
          if journal.notify? &&
              (Setting.notified_events.include?('issue_updated') ||
                (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
                (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
                (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
              )
            # Mailer.issue_edit(journal).deliver
            Mailer.mail_shaper_deliver_issue_edit(journal)
          end
        end

      end
    end
  end
end

