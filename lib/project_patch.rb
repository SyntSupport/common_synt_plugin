module RefinedWatchersList
  module Patches
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          # run code for updating issue
          alias_method_chain :users, :refined_list
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def users_with_refined_list
          users = users_without_refined_list.delete_if{|item| item.lastname =~ /not_user/}
          if (!User.current.allowed_to?(:see_real_names, self, :global => true))
            current_role = User.current.roles_for_project(self)
            filtered_users = []
            users.each {|user|
              user_role = user.roles_for_project(self)
              user_role.each {|role|
                if current_role.member?(role)
                  filtered_users << user
                  break
                end
              }
            }
            return filtered_users
          end
          return users
        end
      end
    end
  end
end

