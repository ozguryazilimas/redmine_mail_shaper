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
          split_users_by_permission(journalized.notified_users, private_notes?)
        end

        def watcher_recipients_can_view_time_entries
          split_users_by_permission(journalized.notified_watchers, private_notes?)
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

        def split_users_by_permission(user_list, for_private_note)
          resp = {
            :can_time_entry => {
              :can_estimated_time => [],
              :can_not_estimated_time => []
            },
            :can_not_time_entry => {
              :can_estimated_time => [],
              :can_not_estimated_time => []
            }
          }

          proj = journalized.project

          user_list.each do |user|
            if !for_private_note || user.rms_can_view_private_notes(proj)
              if user.rms_can_view_time_entries(proj)
                if user.rms_can_view_estimated_time(proj)
                  resp[:can_time_entry][:can_estimated_time] << user.mail
                else
                  resp[:can_time_entry][:can_not_estimated_time] << user.mail
                end
              else
                if user.rms_can_view_estimated_time(proj)
                  resp[:can_not_time_entry][:can_estimated_time] << user.mail
                else
                  resp[:can_not_time_entry][:can_not_estimated_time] << user.mail
                end
              end
            end
          end

          resp
        end

      end
    end
  end
end

