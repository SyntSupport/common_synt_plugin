# require 'redmine'
# require 'date'
# require 'active_support'

# require File.dirname(__FILE__) + '/lib/issues_controller_patch.rb'
# require File.dirname(__FILE__) + '/lib/project_patch.rb'

   require_dependency 'project'
   Project.send(:include, ProjectPatch)

   require_dependency 'watchers_helper'
   WatchersHelper.send(:include, WatchersHelperPatch)

   require_dependency 'user'
   User.send(:include, UserPatch)

   require_dependency 'users_controller'
   UsersController.send(:include, UsersControllerPatch)

   require_dependency 'custom_fields_helper'
   CustomFieldsHelper.send(:include, CustomFieldsHelperPatch)

   require_dependency 'mailer'
   Mailer.send(:include, MailerPatch)

   require_dependency 'query'
   Query.send(:include, QueryPatch)

   require_dependency 'issues_controller'
   IssuesController.send(:include, IssuesControllerPatch)

   require_dependency 'watchers_controller'
   WatchersController.send(:include, WatchersControllerPatch)

Redmine::Plugin.register :common_synt_plugin do
  name 'Common synt plugin'
  author 'Ilya Turkin'
  description 'Common synt plugin is the summary plugin of the other synt plugins'
  version '0.0.1'
  author_url 'https://github.com/SyntSupport'

  # Permissions for assigned to field
  permission :edit_assigned_to, :issues => :index

  # Permissions for due date field
  permission :edit_due_date, :issues => :index

  # Permissions for estimated hours field
  permission :edit_estimated_hours, :issues => :index

  permission :edit_start_date, :issues => :index

  permission :view_members, :issues => :index
  permission :see_real_names, :issues => :index
  permission :edit_custom_fields, :issues => :index
end

