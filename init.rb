require 'redmine'
require 'redmine_mail_shaper'
require 'unified_diff'


Redmine::Plugin.register :redmine_mail_shaper do
  name 'Redmine Mail Shaper plugin'
  author 'Onur Kucuk'
  description 'Format and behaviour changer plugin for Redmine notification e-mails '
  version '2.2.0'
  url 'http://www.ozguryazilim.com.tr'
  author_url 'http://www.ozguryazilim.com.tr'
  requires_redmine :version_or_higher => '2.5.1' # not tested with versions below

  settings :partial => 'redmine_mail_shaper/settings',
    :default => {
      :wiki_diff_on_update => 0,
      :wiki_diff_on_create => 0,
      :issue_show_parent_subject => 0,
      :diff_hunk_line_size => 2,
      :diff_max_lines_displayed => 50,
      :suppress_email_for_attachment => 0,
      :suppress_email_for_time_entry => 0,
      :suppress_email_for_cf => [],
      :suppress_email_for_attr => []
  }

end


Rails.configuration.to_prepare do
  unless TimeEntry.included_modules.include?(RedmineMailShaper::Patches::TimeEntryMailShaperPatch)
    TimeEntry.send(:include, RedmineMailShaper::Patches::TimeEntryMailShaperPatch)
  end
  unless IssuesHelper.included_modules.include?(RedmineMailShaper::Patches::IssuesHelperMailShaperPatch)
    IssuesHelper.send(:include, RedmineMailShaper::Patches::IssuesHelperMailShaperPatch)
  end
#  unless JournalObserver.included_modules.include?(RedmineMailShaper::Patches::JournalObserverMailShaperPatch)
#    JournalObserver.send(:include, RedmineMailShaper::Patches::JournalObserverMailShaperPatch)
#  end
  unless Mailer.included_modules.include?(RedmineMailShaper::Patches::MailerMailShaperPatch)
    Mailer.send(:include, RedmineMailShaper::Patches::MailerMailShaperPatch)
  end
#  unless Issue.included_modules.include?(RedmineMailShaper::Patches::IssueMailShaperPatch)
#    Issue.send(:include, RedmineMailShaper::Patches::IssueMailShaperPatch)
#  end
  unless TimelogController.included_modules.include?(RedmineMailShaper::Patches::TimelogControllerMailShaperPatch)
    TimelogController.send(:include, RedmineMailShaper::Patches::TimelogControllerMailShaperPatch)
  end
  unless Journal.included_modules.include?(RedmineMailShaper::Patches::JournalMailShaperPatch)
    Journal.send(:include, RedmineMailShaper::Patches::JournalMailShaperPatch)
  end
end


