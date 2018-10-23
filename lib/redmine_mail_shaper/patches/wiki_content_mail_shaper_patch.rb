require_dependency 'wiki_content'


module RedmineMailShaper
  module Patches
    module WikiContentMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :send_notification, :mail_shaper
        end
      end

      module InstanceMethods

        private

        # group mails by user language
        def send_notification_with_mail_shaper
          # new_record? returns false in after_save callbacks
          if id_changed?
            if Setting.notified_events.include?('wiki_content_added')
              # Mailer.wiki_content_added(self).deliver
              Mailer.mail_shaper_wiki_content_added(self)
            end
          elsif text_changed?
            if Setting.notified_events.include?('wiki_content_updated')
              # Mailer.wiki_content_updated(self).deliver
              Mailer.mail_shaper_wiki_content_updated(self)
            end
          end
        end

      end
    end
  end
end

