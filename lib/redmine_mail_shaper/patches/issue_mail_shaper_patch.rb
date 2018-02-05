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

        def rms_parent_issue_subject
          if RedmineMailShaper.settings[:issue_show_parent_subject] && parent_issue_id.present?
            parent.subject
          else
            nil
          end
        end

      end
    end
  end
end

