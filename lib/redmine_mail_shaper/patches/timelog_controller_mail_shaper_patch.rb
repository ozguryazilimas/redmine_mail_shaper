require_dependency 'timelog_controller'


module RedmineMailShaper
  module Patches
    module TimelogControllerMailShaperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
          alias_method_chain :create, :mail_shaper
        end
      end

      module InstanceMethods

        def create_with_mail_shaper
          @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
          @time_entry.safe_attributes = params[:time_entry]

          call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })

          if @time_entry.save
            @time_entry.create_journal_entry

            respond_to do |format|
              format.html {
                flash[:notice] = l(:notice_successful_create)
                if params[:continue]
                  if params[:project_id]
                    redirect_to :action => 'new', :project_id => @time_entry.project, :issue_id => @time_entry.issue,
                      :time_entry => {:issue_id => @time_entry.issue_id, :activity_id => @time_entry.activity_id},
                      :back_url => params[:back_url]
                  else
                    redirect_to :action => 'new', 
                      :time_entry => {:project_id => @time_entry.project_id, :issue_id => @time_entry.issue_id, :activity_id => @time_entry.activity_id},
                      :back_url => params[:back_url]
                  end
                else
                  redirect_back_or_default :action => 'index', :project_id => @time_entry.project
                end
              }
              format.api  { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
            end
          else
            respond_to do |format|
              format.html { render :action => 'new' }
              format.api  { render_validation_errors(@time_entry) }
            end
          end
        end

      end
    end
  end
end

