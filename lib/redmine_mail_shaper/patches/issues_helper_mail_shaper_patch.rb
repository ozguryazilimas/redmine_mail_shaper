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
          if Setting[:plugin_redmine_mail_shaper][:issue_show_parent_subject] and issue.parent_issue_id
            Issue.find_by_id(issue.parent_issue_id).subject
          else
            nil
          end
        end

      end
    end
  end
end

