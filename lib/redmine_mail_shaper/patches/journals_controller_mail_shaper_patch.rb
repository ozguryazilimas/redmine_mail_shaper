require_dependency 'journals_controller'


module RedmineMailShaper
  module Patches
    module JournalsControllerMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :new, :mail_shaper
        end
      end

      module InstanceMethods

        # force excerpts from another journal note to start with user language
        # instead of system language
        def new_with_mail_shaper
          @journal = Journal.visible.find(params[:journal_id]) if params[:journal_id]
          if @journal
            user = @journal.user
            text = @journal.notes
          else
            user = @issue.author
            text = @issue.description
          end
          # Replaces pre blocks with [...]
          text = text.to_s.strip.gsub(%r{<pre>(.*?)</pre>}m, '[...]')
          # The only change is for this line
          # @content = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
          user_language = user.language || Setting.default_language
          @content = "#{ll(user_language, :text_user_wrote, user)}\n> "
          @content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
        rescue ActiveRecord::RecordNotFound
          render_404
        end

      end
    end
  end
end

