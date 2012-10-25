require_dependency 'issue'

module RedmineMailShaper
  module Patches
    module IssueMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
        end
      end

      module InstanceMethods

        def recipients_can_view_time_entries
          # allowed_to?(:view_time_entries, @project)
          notified = []
          # Author and assignee are always notified unless they have been
          # locked or don't want to be notified
          notified << author if author
          if assigned_to
            notified += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
          end
          if assigned_to_was
            notified += (assigned_to_was.is_a?(Group) ? assigned_to_was.users : [assigned_to_was])
          end
          notified = notified.select {|u| u.active? && u.notify_about?(self)}

          notified += project.notified_users
          notified.uniq!
          # Remove users that can not view the issue
          notified.reject! {|user| !visible?(user)}

          notified_can = notified.select {|k| k.allowed_to?(:view_time_entries, project)}
          notified_can_not = notified - notified_can

          # allowed_to?(:view_time_entries, @project)
          [notified_can.collect(&:mail), notified_can_not.collect(&:mail)]
        end

        # Returns an array of watchers' email addresses
        def watcher_recipients_can_view_time_entries
          notified = watcher_users.active
          notified.reject! {|user| user.mail_notification == 'none'}

          if respond_to?(:visible?)
            notified.reject! {|user| !visible?(user)}
          end

          notified_can = notified.select {|k| k.allowed_to?(:view_time_entries, project)}
          notified_can_not = notified - notified_can

          # allowed_to?(:view_time_entries, @project)
          [notified_can.collect(&:mail).compact, notified_can_not.collect(&:mail).compact]
        end

      end
    end
  end
end

