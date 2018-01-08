module RedmineMailShaper

  def self.settings
    (Setting[:plugin_redmine_mail_shaper] || {}).with_indifferent_access
  end

end

