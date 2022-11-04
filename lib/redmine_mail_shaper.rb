require_dependency File.join(File.dirname(__FILE__), 'redmine_mail_shaper/hooks/controller_issues_edit_before_save_hook')

module RedmineMailShaper

  def self.settings
    HashWithIndifferentAccess.new(Setting[:plugin_redmine_mail_shaper])
  end

end

