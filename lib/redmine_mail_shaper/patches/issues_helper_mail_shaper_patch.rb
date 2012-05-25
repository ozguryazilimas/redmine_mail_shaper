require_dependency 'issues_helper'


module RedmineMailShaper
  module Patches
    module IssuesHelperMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
        end
      end

      module InstanceMethods

        def parent_issue_subject(issue)
          issue.parent_issue_id.blank? ? nil : Issue.find_by_id(issue.parent_issue_id).subject
        end

      end
    end
  end
end

