module RedmineMailShaper
  module Hooks
    class ControllerIssuesEditBeforeSaveHook < Redmine::Hook::ViewListener

      def controller_issues_edit_before_save(context = {})
        retval = true
        return retval unless RedmineMailShaper.settings[:time_entry_create_journal]

        # @time_entry is defined in controller, do not override it
        te = context[:time_entry]
        return retval unless te

        obj_old_value = {
          'hours_was' => 0,
          'hours' => te.hours,
          'comments_was' => '',
          'comments' => " (#{te.comments})",
          'activity_name_was' => '',
          'activity_name' => te.activity.try(:name)
        }

        context[:journal].details << JournalDetail.new(
          :property => 'time_entry',
          :prop_key => te.id,
          :value => 'create',
          :old_value => obj_old_value.to_yaml
        )

        retval
      end

      # Redmine does not allow creating time entry during issue create at the moment, enable below
      # if it happens
      # alias_method :controller_issues_new_before_save, :controller_issues_edit_before_save
    end

  end
end

