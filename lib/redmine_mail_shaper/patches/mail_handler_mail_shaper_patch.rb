require_dependency 'mail_handler'


module RedmineMailShaper
  module Patches
    module MailHandlerMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
        end
      end

      module InstanceMethods

        private

        def receive_time_entry_reply(time_entry_id)
          te = TimeEntry.find(time_entry_id)

          if te.issue_id
            receive_issue_reply(te.issue_id)
          else
            begin
              rms_email_sender = @email.from.to_a.first.to_s.strip
            rescue
              rms_email_sender = 'unknown'
            end

            logger.info "MailHandler: MailShaper could find TimeEntry for id #{time_entry_id}, skipping email process from #{rms_email_sender}"
          end
        end

      end

    end
  end
end

