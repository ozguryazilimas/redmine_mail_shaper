require_dependency 'user'


module RedmineMailShaper
  module Patches
    module UserMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
        end
      end

      module InstanceMethods

        def rms_can_view_estimated_time(perm_project)
          has_perm = true

          # check if redmine_hide_estimated_hours_permission plugin is used
          # that plugin has weird permission to 'hide' a permission
          if respond_to?(:deny_view_estimated_time?)
            has_perm = admin? || !allowed_to?(:hide_estimated_time, perm_project)
          end

          has_perm
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

