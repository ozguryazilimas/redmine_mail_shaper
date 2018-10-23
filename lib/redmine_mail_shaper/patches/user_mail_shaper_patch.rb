require_dependency 'user'


module RedmineMailShaper
  module Patches
    module UserMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods

        def rms_can_view_estimated_time(perm_project)
          # check if redmine_hide_estimated_hours_permission plugin is used
          # that plugin has weird permission to 'hide' a permission. Alternatively
          # if redmine_hide_estimated_hours plugin is used, it uses view_time_entries
          # permission that is already in redmine. If none of these are used, still
          # view_time_entries is a good place to decide on permissions
          if respond_to?(:deny_view_estimated_time?)
            !allowed_to?(:hide_estimated_time, perm_project)
          else
            allowed_to?(:view_time_entries, perm_project)
          end
        end

        def rms_can_view_time_entries(perm_project)
          allowed_to?(:view_time_entries, perm_project)
        end

        def rms_can_view_private_notes(perm_project)
          allowed_to?(:view_private_notes, perm_project)
        end

      end

    end
  end
end

