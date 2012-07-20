module MandatoryFieldsAndStatusAutochange
  module Patches
    module IssuesControllerPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
 # run code for updating issue
          alias_method_chain :update, :write_due_date
           # for the watchers adding by mail
          alias_method_chain :create, :watchers_adding
        end

      end

      module ClassMethods
      end

      module InstanceMethods
        def create_with_watchers_adding
          if params.key? 'watcher_mails' and params[:watcher_mails] != ""
            mail_errors, ids = User.create_users_by_mails(params[:watcher_mails],@project.id)
            mail_errors.each do |message|
              @issue.errors.add_to_base(message)
            end
            if @issue.errors.full_messages.empty? and not ids.empty?
              ids.each do |id|
		tmp_user = User.find(id)
                @issue.add_watcher(tmp_user) if not @issue.watched_by? tmp_user
              end
            end

            call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
            IssueObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
            if @issue.errors.empty? && @issue.save
              attachments = Attachment.attach_files(@issue, params[:attachments])
              render_attachment_warning_if_needed(@issue)
              flash[:notice] = l(:notice_successful_create)
              call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
              respond_to do |format|
                format.html {
                  redirect_to(params[:continue] ?  { :action => 'new', :project_id => @project, :issue => {:tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id}.reject {|k,v| v.nil?} } :
                              { :action => 'show', :id => @issue })
                }
                format.api  { render :action => 'show', :status => :created, :location => issue_url(@issue) }
              end
              return
            else
              respond_to do |format|
                format.html { render :action => 'new' }
                format.api  { render_validation_errors(@issue) }
              end
            end
          else
            create_without_watchers_adding
          end
        end

        # when updating an issues due_date
        def update_with_write_due_date
          if (params[:issue].key?(:status_id))
            #issue = Issue.find(params[:id])
            status = IssueStatus.find(params[:issue][:status_id])
            if params[:commit] == l(:submit_button_ask_user)
              params[:issue][:status_id] = 11 #ожидается ответ заказчика
            else
              if (params[:issue][:due_date].nil? || (params[:issue][:due_date] == '')) && status.is_closed?
                params[:issue][:due_date] = Time.current
              end
              case status.id
                when 11 #ожидается ответ заказчика
                    if !User.current.allowed_to?(:see_real_names, @project, :global => true)
                      params[:issue][:status_id] = 10 #ответ заказчика дан
                    end
                when 5 #закрыто
                   if (params[:issue][:custom_field_values]["2"] == "")
                     @issue.errors.add( :custom_2, :blank)
                   end
                   if (params[:issue][:custom_field_values]["9"] == "")
                     @issue.errors.add( :custom_9, :blank)
                   end
                   if (params[:issue][:custom_field_values]["5"] == "")
                     @issue.errors.add( :custom_5, :blank)
                   end
                   if (params[:issue][:estimated_hours] == "")
                     @issue.errors.add( :estimated_hours, :blank)
                   end
                   if @issue.errors.count != 0
                    update_issue_from_params
                    render :action => 'edit'
                    return
                   end
                when 12 #Выполнено
                   if (params.key?(:time_entry) && params[:time_entry][:hours] == "")
                    @issue.errors.add( :time_entries, :blank)
                   end
                   if @issue.errors.count != 0
                    update_issue_from_params
                    render :action => 'edit'
                    return
                   end
              end
            end
          end
          update_without_write_due_date
        end
      end
    end
  end
end

