require 'redmine'
require 'redmine_mail_shaper'
require 'unified_diff'


Redmine::Plugin.register :redmine_mail_shaper do
  name 'Redmine Mail Shaper plugin'
  author 'Onur Küçük'
  description 'Format and behaviour changer plugin for Redmine notification e-mails '
  version '0.1.0'
  url 'http://www.ozguryazilim.com.tr'
  author_url 'http://www.ozguryazilim.com.tr'
  requires_redmine :version_or_higher => '1.4.0' # not tested with versions below
end


