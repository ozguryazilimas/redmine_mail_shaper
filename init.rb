require 'redmine_mail_shaper'
require 'unified_diff'


Redmine::Plugin.register :redmine_mail_shaper do
  name 'Redmine Mail Shaper plugin'
  author 'Onur Kucuk'
  description 'Format and behaviour changer plugin for Redmine notification e-mails '
  version '2.7.0'
  url 'http://www.ozguryazilim.com.tr'
  author_url 'http://www.ozguryazilim.com.tr'
  requires_redmine :version_or_higher => '2.5.1'

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
      :suppress_email_for_attr => [],
      :time_entry_send_email => 0,
      :time_entry_create_journal => 0
  }

end

Rails.configuration.to_prepare do
  [
    [IssuesHelper, RedmineMailShaper::Patches::IssuesHelperMailShaperPatch],
    [TimeEntry, RedmineMailShaper::Patches::TimeEntryMailShaperPatch],
    [Mailer, RedmineMailShaper::Patches::MailerMailShaperPatch],
    [TimelogController, RedmineMailShaper::Patches::TimelogControllerMailShaperPatch],
    [Journal, RedmineMailShaper::Patches::JournalMailShaperPatch],
    [User, RedmineMailShaper::Patches::UserMailShaperPatch],
    [Issue, RedmineMailShaper::Patches::IssueMailShaperPatch],
    [JournalsController, RedmineMailShaper::Patches::JournalsControllerMailShaperPatch],
    [WikiContent, RedmineMailShaper::Patches::WikiContentMailShaperPatch]
  ].each do |classname, modulename|
    unless classname.included_modules.include?(modulename)
      classname.send(:include, modulename)
    end
  end

end

