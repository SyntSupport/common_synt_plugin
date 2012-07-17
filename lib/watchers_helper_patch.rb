module RefinedWatchersList
  module Patches
    module WatchersHelperPatch
      def self.included(base)
        #base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          # run code for updating issue
          alias_method_chain :watchers_list, :filter
        end
      end

      module ClassMethods

      end

      module InstanceMethods
        def watchers_list_with_filter(object)
          lis = watchers_list_without_filter(object)
          lis_filt = ""
          unless lis == ""
            watchers_arr = lis.split("\n")
            watchers_arr.each do |watcher|
              if /Syntellect/.match watcher
                if /<ul>/.match watcher
                  lis_filt << "<ul>"
                elsif /<\/ul>/.match watcher
                  lis_filt << "</ul>"
                end
              else
                watcher.slice!(" not_user")
                lis_filt << watcher << "\n"
              end
            end
          end
          return lis_filt
        end
      end
    end
  end
end

