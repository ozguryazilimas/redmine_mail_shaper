require_dependency 'journal'

module RedmineMailShaper
  module Patches
    module JournalMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
          alias_method_chain :send_notification, :mail_shaper
        end
      end

      module InstanceMethods

        def recipients_can_view_time_entries
          notified = journalized.notified_users
          if private_notes?
            notified = notified.select {|user| user.allowed_to?(:view_private_notes, journalized.project)}
          end

          notified_can = notified.select {|k| k.allowed_to?(:view_time_entries, journalized.project)}
          notified_can_not = notified - notified_can

          [notified_can.map(&:mail), notified_can_not.map(&:mail)]
        end

        def watcher_recipients_can_view_time_entries
          notified = journalized.notified_watchers
          if private_notes?
            notified = notified.select {|user| user.allowed_to?(:view_private_notes, journalized.project)}
          end

          notified_can = notified.select {|k| k.allowed_to?(:view_time_entries, journalized.project)}
          notified_can_not = notified - notified_can

          [notified_can.map(&:mail), notified_can_not.map(&:mail)]
        end

        def send_notification_with_mail_shaper
          if notify? && (Setting.notified_events.include?('issue_updated') ||
              (Setting.notified_events.include?('issue_note_added') && notes.present?) ||
              (Setting.notified_events.include?('issue_status_updated') && new_status.present?) ||
              (Setting.notified_events.include?('issue_priority_updated') && new_value_for('priority_id').present?)
            )
            # Mailer.deliver_issue_edit(self)
            Mailer.mail_shaper_deliver_issue_edit(self) unless should_not_send_email(self)
          end
        end


        private

        def should_not_send_email(journal)
          ret = false
          settings = RedmineMailShaper.settings

          if journal.notes.blank? and (journal.details.count == 1)
            detail = journal.details.first
            Rails.logger.debug "should_not_send_email working on JournalDetail: #{detail.id}"

            case detail.property
            when 'attachment'
              ret = settings[:suppress_email_for_attachment]
            when 'time_entry'
              ret = settings[:suppress_email_for_time_entry]
            when 'attr'
              unless settings[:suppress_email_for_attr].blank?
                ret = settings[:suppress_email_for_attr].include? detail.prop_key
              end
            when 'cf'
              unless settings[:suppress_email_for_cf].blank?
                custom_field = CustomField.find_by_id(detail.prop_key)
                ret = settings[:suppress_email_for_cf].include? custom_field.name
              end
            end

          end

          Rails.logger.debug "should_not_send_email returns #{ret.inspect}"
          ret
        end


      end
    end
  end
end

