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
            Mailer.mail_shaper_deliver_issue_edit(journal) unless should_not_send_email(journal)
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

