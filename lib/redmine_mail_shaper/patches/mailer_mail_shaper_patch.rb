require_dependency 'mailer'


module RedmineMailShaper
  module Patches
    module MailerMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode

          def self.mail_shaper_deliver_issue_edit(journal)
            if journal.details.select{|k| (k.property == 'time_entry') || (k.prop_key == 'estimated_hours')}.blank?
              self.deliver_issue_edit(journal)
            else
              recipient_users = journal.recipients_can_view_time_entries
              watcher_users = journal.watcher_recipients_can_view_time_entries
              all_langs = (recipient_users[:language].keys + watcher_users[:language].keys).uniq

              # if there is only time_entry on issue/edit change make sure we do not send blank
              # emails to recipients who should not see time entries
              if journal.notes.blank?
                jd_all = journal.details
                jd_time_entry = jd_all.select{|k| k.property == 'time_entry'}
                jd_estimated_time = jd_all.select{|k| k.prop_key == 'estimated_hours'}

                # if we have anything other than time entry or estimated time, send the mail
                # if we only have time entry, skip the ones can not see time entry
                # if we only have estimated time, skip the ones can not see estimated time
                if (jd_all - jd_time_entry - jd_estimated_time).count == 0
                  if (jd_all - jd_time_entry).count == 0
                    recipient_users[:can_not_time_entry][:can_estimated_time] = []
                    recipient_users[:can_not_time_entry][:can_not_estimated_time] = []

                    watcher_users[:can_not_time_entry][:can_estimated_time] = []
                    watcher_users[:can_not_time_entry][:can_not_estimated_time] = []
                  end

                  if (jd_all - jd_estimated_time).count == 0
                    recipient_users[:can_time_entry][:can_not_estimated_time] = []
                    recipient_users[:can_not_time_entry][:can_not_estimated_time] = []

                    watcher_users[:can_time_entry][:can_not_estimated_time] = []
                    watcher_users[:can_not_time_entry][:can_not_estimated_time] = []
                  end
                end
              end

              @language_without_mail_shaper = current_language

              # make sure we do not use the language key on iterating through recipient types
              recipient_users.except(:language).each do |time_entry_key, subhash|
                subhash.each do |estimated_time_key, val|
                  selected_recipients = recipient_users[time_entry_key][estimated_time_key]
                  selected_watchers = watcher_users[time_entry_key][estimated_time_key]

                  all_langs.each do |lang|
                    recipient_with_lang = (recipient_users[:language][lang] || []) & (selected_recipients || [])
                    watcher_with_lang = (watcher_users[:language][lang] || []) & (selected_watchers || [])

                    if recipient_with_lang.present? || watcher_with_lang.present?
                      # setting language here does not affect email rendering language, no soup for you
                      # set_language_if_valid lang

                      mail_shaper_issue_edit(
                        journal,
                        recipient_with_lang,
                        watcher_with_lang,
                        time_entry_key == :can_time_entry,
                        estimated_time_key == :can_estimated_time,
                        lang
                      ).deliver
                    end
                  end
                end
              end

              set_language_if_valid @language_without_mail_shaper
            end
          end

          # default issue add with lang support
          def issue_add(issue, to_users, cc_users, lang = nil)
            set_language_if_valid(lang) if lang.present?

            redmine_headers 'Project' => issue.project.identifier,
                            'Issue-Id' => issue.id,
                            'Issue-Author' => issue.author.login
            redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
            message_id issue
            references issue
            @author = issue.author
            @issue = issue
            @users = to_users + cc_users
            @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
            mail :to => to_users.map(&:mail),
              :cc => cc_users.map(&:mail),
              :subject => "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
          end


          # default issue_edit with updated headers and lang support
          def issue_edit(journal, to_users, cc_users, lang = nil)
            set_language_if_valid(lang) if lang.present?

            issue = journal.journalized.reload
            redmine_headers 'Project' => issue.project.identifier,
                            'Issue-Id' => issue.id,
                            'Issue-Author' => issue.author.login
            redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
            redmine_headers 'Issue-Edit-Has-Note' => (journal.notes.blank? ? 'No' : 'Yes')
            message_id journal
            references issue
            @author = journal.user
            s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
            s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
            s << issue.subject
            @issue = issue
            @users = to_users + cc_users
            @journal = journal
            @journal_details = journal.visible_details(@users.first)
            @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
            mail :to => to_users.map(&:mail),
              :cc => cc_users.map(&:mail),
              :subject => s
          end

          # override mailer methods to send users email in their language
          def self.deliver_issue_edit(journal)
            issue = journal.journalized.reload
            to_raw = journal.notified_users
            cc_raw = journal.notified_watchers - to_raw

            all_langs = (to_raw + cc_raw).map(&:language).uniq
            @language_without_mail_shaper = current_language

            all_langs.each do |lang|
              to = to_raw.select{|k| k.language == lang}
              cc = cc_raw.select{|k| k.language == lang}

              if (to + cc).present?
                journal.each_notification(to + cc) do |users|
                  issue.each_notification(users) do |users2|
                    Mailer.issue_edit(journal, to & users2, cc & users2, lang).deliver
                  end
                end
              end
            end

            set_language_if_valid @language_without_mail_shaper
          end

          # override mailer methods to send users email in their language
          def self.deliver_issue_add(issue)
            to_raw = issue.notified_users
            cc_raw = issue.notified_watchers - to_raw

            all_langs = (to_raw + cc_raw).map(&:language).uniq
            @language_without_mail_shaper = current_language

            all_langs.each do |lang|
              to = to_raw.select{|k| k.language == lang}
              cc = cc_raw.select{|k| k.language == lang}

              if (to + cc).present?
                issue.each_notification(to + cc) do |users|
                  Mailer.issue_add(issue, to & users, cc & users, lang).deliver
                end
              end
            end

            set_language_if_valid @language_without_mail_shaper
          end

          def mail_shaper_wiki_content_deliver_email(wiki_content, old_recipients, old_cc, typeof_delivery)
            lang_with_users = User.joins(:email_address).where('email_addresses.address in (?)', old_recipients + old_cc).group_by(&:language)
            @language_without_mail_shaper = current_language

            lang_with_users.each do |lang, users_obj|
              users = users_obj.map(&:mail)
              recipients = old_recipients & users
              cc = old_cc & users

              if recipients.present? || cc.present?
                case typeof_delivery
                when 'updated'
                  Mailer.wiki_content_updated(wiki_content, recipients, cc, lang).deliver
                when 'added'
                  Mailer.wiki_content_added(wiki_content, recipients, cc, lang).deliver
                end
              end
            end

            set_language_if_valid @language_without_mail_shaper
          end

          def self.mail_shaper_wiki_content_added(wiki_content)
            old_recipients = wiki_content.recipients
            old_cc = wiki_content.page.wiki.watcher_recipients - old_recipients

            mail_shaper_wiki_content_deliver_email(wiki_content, old_recipients, old_cc, 'added')
          end

          def self.mail_shaper_wiki_content_updated(wiki_content)
            old_recipients = wiki_content.recipients
            old_cc = wiki_content.page.wiki.watcher_recipients + wiki_content.page.watcher_recipients - old_recipients

            mail_shaper_wiki_content_deliver_email(wiki_content, old_recipients, old_cc, 'updated')
          end

          # default wiki_content_added with forced recipients and cc
          def wiki_content_added(wiki_content, recipients, cc, lang)
            set_language_if_valid lang

            redmine_headers 'Project' => wiki_content.project.identifier,
                            'Wiki-Page-Id' => wiki_content.page.id
            @author = wiki_content.author
            message_id wiki_content
            # recipients = wiki_content.recipients
            # cc = wiki_content.page.wiki.watcher_recipients - recipients
            @wiki_content = wiki_content
            @wiki_content_url = url_for(:controller => 'wiki', :action => 'show',
                                              :project_id => wiki_content.project,
                                              :id => wiki_content.page.title)
            mail :to => recipients,
              :cc => cc,
              :subject => "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_added, :id => wiki_content.page.pretty_title)}"
          end

          # default wiki_content_updated with forced recipients and cc
          def wiki_content_updated(wiki_content, recipients, cc, lang)
            set_language_if_valid lang

            redmine_headers 'Project' => wiki_content.project.identifier,
                            'Wiki-Page-Id' => wiki_content.page.id
            @author = wiki_content.author
            message_id wiki_content
            # recipients = wiki_content.recipients
            # cc = wiki_content.page.wiki.watcher_recipients + wiki_content.page.watcher_recipients - recipients
            @wiki_content = wiki_content
            @wiki_content_url = url_for(:controller => 'wiki', :action => 'show',
                                              :project_id => wiki_content.project,
                                              :id => wiki_content.page.title)
            @wiki_diff_url = url_for(:controller => 'wiki', :action => 'diff',
                                           :project_id => wiki_content.project, :id => wiki_content.page.title,
                                           :version => wiki_content.version)
            mail :to => recipients,
              :cc => cc,
              :subject => "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_updated, :id => wiki_content.page.pretty_title)}"
          end

        end
      end

      module InstanceMethods

        # Builds a tmail object used to email recipients of the edited issue. Called only on time_entry changes
        def mail_shaper_issue_edit(journal, ms_recipients, ms_watchers, can_view_time_entries, can_view_estimated_time, lang = nil)
          set_language_if_valid(lang) if lang.present?

          issue = journal.journalized.reload
          redmine_headers 'Project' => issue.project.identifier,
                          'Issue-Id' => issue.id,
                          'Issue-Author' => issue.author.login
          redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
          redmine_headers 'Issue-Edit-Has-Note' => (journal.notes.blank? ? 'No' : 'Yes')
          message_id journal
          references issue
          @author = journal.user
          recipients = ms_recipients
          @users = recipients
          # Watchers in cc
          cc = ms_watchers - recipients
          s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
          s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
          s << issue.subject
          @issue = issue
          @journal = journal
          @journal_details = journal.visible_details(User.joins(:email_address).where('email_addresses.address in (?)', [@users.first]).first)
          @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
          @can_view_time_entries = can_view_time_entries
          @can_view_estimated_time = can_view_estimated_time
          mail :to => recipients,
            :cc => cc,
            :subject => s
        end

        def time_entry_edit(time_entry, for_type, notified, activity_name_was)
          redmine_headers 'Project' => time_entry.project.identifier
          redmine_headers 'Time-Entry-Only' => 'Yes'
          @author = time_entry.user
          message_id time_entry

          @time_entry = time_entry
          @issue = time_entry.issue
          redmine_headers 'Time-Entry-Has-Issue' => (@issue.blank? ? 'No' : 'Yes')

          @for_type = for_type
          @time_entry_url = url_for(:controller => 'timelog', :action => 'edit', :id => time_entry.id)
          @activity_name = time_entry.activity.name
          @activity_name_was = activity_name_was
          @comments = time_entry.comments
          @comments_was = time_entry.comments_was
          @hours = time_entry.hours
          @hours_was = time_entry.hours_was

          @time_entry_attrs = {
            'activity_name' => @activity_name,
            'activity_name_was' => @activity_name_was,
            'comments' => " (#{@comments})",
            'comments_was' => " (#{@comments_was})",
            'hours' => @hours,
            'hours_was' => @hours_was
          }

          if @issue
            redmine_headers 'Issue-Id' => @issue.id,
                            'Issue-Author' => @issue.author.login
            redmine_headers 'Issue-Assignee' => @issue.assigned_to.login if @issue.assigned_to

            # try to cleanup time_entry references object, this is the last resort, try not to open the line below
            # @references_objects = []
            references @issue
            message_id @issue

            issue_last_journal_id = @issue.last_journal_id
            if issue_last_journal_id
              @issue_url = url_for(:controller => 'issues', :action => 'show', :id => @issue, :anchor => "change-#{issue_last_journal_id}")
            else
              @issue_url = url_for(:controller => 'issues', :action => 'show', :id => @issue)
            end

            @subject = "[#{@issue.project.name} - #{@issue.tracker.name} ##{@issue.id}] #{@issue.subject} - "
            @subject << l("journal_entry_time_entry_#{for_type}")
          else
            @subject = "[#{time_entry.project.name}] " + l("journal_entry_time_entry_#{for_type}")
          end

          mail :to => notified,
            :subject => @subject
        end

      end
    end
  end
end

