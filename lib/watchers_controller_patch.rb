module RefinedWatchersList
  module Patches
    module WatchersControllerPatch
      def self.included(base)
        #base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          # run code for updating issue
          alias_method_chain :new, :watchers_adding
        end
      end

      module ClassMethods

      end

      module InstanceMethods
        def new_with_watchers_adding
          if params['watcher_mails'] != ""
            mail_errors, ids = User.create_users_by_mails(params[:watcher_mails],@watched.project.id)
            if mail_errors.empty? and not ids.empty?
              if not params.key? :user_ids
                params[:user_ids] = []
              end
              ids.each do |id|
                params[:user_ids] << id.to_s if not params[:user_ids].include? id.to_s
              end
            end
          end
          new_without_watchers_adding
        end
      end
    end
  end
end

