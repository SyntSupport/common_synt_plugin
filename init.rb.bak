require 'redmine'
require 'date'
require 'active_support'

require File.dirname(__FILE__) + '/lib/issues_controller_patch.rb'
require File.dirname(__FILE__) + '/lib/project_patch.rb'
require File.dirname(__FILE__) + '/lib/watchers_helper_patch.rb'
require File.dirname(__FILE__) + '/lib/user_patch.rb'

require 'dispatcher'
Dispatcher.to_prepare :common_synt_plugin do
  require_dependency 'issues_controller'
  IssuesController.send(:include, MandatoryFieldsAndStatusAutochange::Patches::IssuesControllerPatch)

  require_dependency 'project'
  Project.send(:include, RefinedWatchersList::Patches::ProjectPatch)
  require_dependency 'watchers_helper'
  WatchersHelper.send(:include, RefinedWatchersList::Patches::WatchersHelperPatch)

  #require_dependency 'project'
  require_dependency 'user'
  User.send(:include, StrongPasswordCheck::Patches::UserPatch)
end

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
end

