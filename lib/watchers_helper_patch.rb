module WatchersHelperPatch
  def self.included(base)
    #base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
    end
  end

  module ClassMethods

  end

  module InstanceMethods
    def self.included(receiver)
      receiver.class_eval do
        def watchers_list(object)
          remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
          content = ''.html_safe
          lis = object.watcher_users.collect do |user|
            if user.name == "Syntellect"
              next
            end
            user.name.slice!(" not_user")
            s = ''.html_safe
            s << avatar(user, :size => "16").to_s
            s << link_to_user(user, :class => 'user')
            if remove_allowed
              url = {:controller => 'watchers',
                     :action => 'destroy',
                     :object_type => object.class.to_s.underscore,
                     :object_id => object.id,
                     :user_id => user}
              s << ' '
              s << link_to(image_tag('delete.png'), url,
                           :remote => true, :method => 'delete', :class => "delete")
            end
            content << content_tag('li', s, :class => "user-#{user.id}")
          end
          content.present? ? content_tag('ul', content, :class => 'watchers') : content
        end
      end
    end
  end
end


