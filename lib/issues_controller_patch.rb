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
        end
      end

      module ClassMethods
      end

      module InstanceMethods
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

