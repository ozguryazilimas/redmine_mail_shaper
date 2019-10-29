require_dependency 'journal'


module RedmineMailShaper
  module Patches
    module JournalMailShaperPatch

      def send_notification
        if notify? && (Setting.notified_events.include?('issue_updated') ||
            (Setting.notified_events.include?('issue_note_added') && notes.present?) ||
            (Setting.notified_events.include?('issue_status_updated') && new_status.present?) ||
            (Setting.notified_events.include?('issue_assigned_to_updated') && detail_for_attribute('assigned_to_id').present?) ||
            (Setting.notified_events.include?('issue_priority_updated') && new_value_for('priority_id').present?)
          )
          # Mailer.deliver_issue_edit(self)
          Mailer.deliver_issue_edit(self) unless should_not_send_email(self)
        end
      end

      def visible_details(user=User.current)
        found_details = super

        user_can_view_time_entries = user.rms_can_view_time_entries(project)
        user_can_view_estimated_time = user.rms_can_view_estimated_time(project)

        found_details.reject do |detail|
          detail.property.to_s == 'time_entry' && !user_can_view_time_entries ||
          detail.property.to_s == 'estimated_hours' && !user_can_view_estimated_time
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
            ret = !settings[:time_entry_send_email] || settings[:suppress_email_for_time_entry]
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

Journal.prepend(RedmineMailShaper::Patches::JournalMailShaperPatch)


