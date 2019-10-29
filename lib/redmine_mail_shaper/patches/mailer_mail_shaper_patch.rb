require_dependency 'mailer'


module RedmineMailShaper
  module Patches
    module MailerMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do

          # the only difference is Sender-Role header
          def issue_add(user, issue)
            redmine_headers 'Project' => issue.project.identifier,
                            'Issue-Id' => issue.id,
                            'Issue-Author' => issue.author.login
            redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to

            issue.author.roles_for_project(issue.project).map(&:name).each do |role_name|
              redmine_headers 'Sender-Role' => role_name
            end

            message_id issue
            references issue
            @author = issue.author
            @issue = issue
            @user = user
            @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
            mail :to => user,
              :subject => "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
          end

          # the only difference is Issue-Edit-Has-Note and Sender-Role headers
          def issue_edit(user, journal)
            issue = journal.journalized
            redmine_headers 'Project' => issue.project.identifier,
                            'Issue-Id' => issue.id,
                            'Issue-Author' => issue.author.login
            redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
            redmine_headers 'Issue-Edit-Has-Note' => (journal.notes.blank? ? 'No' : 'Yes')

            journal.user.roles_for_project(issue.project).map(&:name).each do |role_name|
              redmine_headers 'Sender-Role' => role_name
            end

            message_id journal
            references issue
            @author = journal.user
            s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
            s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
            s << issue.subject
            @issue = issue
            @user = user
            @journal = journal
            @journal_details = journal.visible_details
            @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")

            mail :to => user,
              :subject => s
          end


          # Wiki
          def wiki_content_added(user, wiki_content)
            redmine_headers 'Project' => wiki_content.project.identifier,
                            'Wiki-Page-Id' => wiki_content.page.id
            @author = wiki_content.author
            @author.roles_for_project(wiki_content.project).map(&:name).each do |role_name|
              redmine_headers 'Sender-Role' => role_name
            end

            message_id wiki_content
            @wiki_content = wiki_content
            @wiki_content_url = url_for(:controller => 'wiki', :action => 'show',
                                              :project_id => wiki_content.project,
                                              :id => wiki_content.page.title)
            mail :to => user,
              :subject => "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_added, :id => wiki_content.page.pretty_title)}"
          end


          # Builds a mail to user about an update of the specified wiki content.
          def wiki_content_updated(user, wiki_content)
            redmine_headers 'Project' => wiki_content.project.identifier,
                            'Wiki-Page-Id' => wiki_content.page.id
            @author = wiki_content.author
            @author.roles_for_project(wiki_content.project).map(&:name).each do |role_name|
              redmine_headers 'Sender-Role' => role_name
            end

            message_id wiki_content
            @wiki_content = wiki_content
            @wiki_content_url = url_for(:controller => 'wiki', :action => 'show',
                                              :project_id => wiki_content.project,
                                              :id => wiki_content.page.title)
            @wiki_diff_url = url_for(:controller => 'wiki', :action => 'diff',
                                           :project_id => wiki_content.project, :id => wiki_content.page.title,
                                           :version => wiki_content.version)
            mail :to => user,
              :subject => "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_updated, :id => wiki_content.page.pretty_title)}"
          end

          def self.deliver_time_entry_edit(time_entry, for_type, activity_name_was)
            users = time_entry.project.notified_users.select do |user|
              user.allowed_to?(:view_time_entries, time_entry.project)
            end.uniq

            author = User.anonymous.try(:id) == User.current.try(:id) ? time_entry.user : User.current

            time_entry_args = {
              :author => author,
              :for_type => for_type,
              :issue => time_entry.issue,
              :activity_name_was => activity_name_was,
              :activity_name => time_entry.activity.try(:name),
              :comments => time_entry.comments,
              :comments_was => time_entry.comments_before_last_save,
              :hours => time_entry.hours,
              :hours_was => time_entry.hours_before_last_save
            }

            users.each do |user|
              time_entry_edit(user, time_entry, time_entry_args).deliver_later
            end
          end

        end
      end

      module InstanceMethods

        def time_entry_edit(user, time_entry, args)
          redmine_headers 'Project' => time_entry.project.identifier
          redmine_headers 'Time-Entry-Only' => 'Yes'
          @author = args[:author]
          message_id time_entry

          @user = user
          @time_entry = time_entry
          @issue = args[:issue]
          redmine_headers 'Time-Entry-Has-Issue' => (@issue.blank? ? 'No' : 'Yes')

          @for_type = args[:for_type]
          @time_entry_url = url_for(:controller => 'timelog', :action => 'edit', :id => time_entry.id)
          @activity_name = args[:activity_name]
          @activity_name_was = args[:activity_name_was]
          @comments = args[:comments]
          @comments_was = args[:comments_was]
          @hours = args[:hours]
          @hours_was = args[:hours_was]

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

            @author.roles_for_project(@issue.project).map(&:name).each do |role_name|
              redmine_headers 'Sender-Role' => role_name
            end

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

          mail :to => user,
            :subject => @subject
        end

      end
    end
  end
end

