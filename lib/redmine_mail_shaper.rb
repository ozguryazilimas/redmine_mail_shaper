module RedmineMailShaper

  def self.settings
    HashWithIndifferentAccess.new(Setting[:plugin_redmine_mail_shaper])
  end

end

