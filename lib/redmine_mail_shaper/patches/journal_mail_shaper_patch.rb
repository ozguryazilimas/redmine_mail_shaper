require_dependency 'journal'

module RedmineMailShaper
  module Patches
    module JournalMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
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

      end
    end
  end
end

