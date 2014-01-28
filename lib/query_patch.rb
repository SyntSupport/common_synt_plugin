module QueryPatch
  module ClassMethods
    
  end
  
  module InstanceMethods
    def self.included(receiver)
      receiver.class_eval do
        # not to allow a customer to filter tasks by workers names
        def available_filters
          unless @available_filters
            initialize_available_filters
            if User.current.client?
              @available_filters.except!("member_of_group", "assigned_to_role")
            end
            @available_filters.each do |field, options|
              if User.current.client? && 
                  (field == "author_id" || field == "assigned_to_id" ||
                   field == "watcher_id")
                options[:values].select!{|x| x[0] != "Syntellect"} if 
                  options.key?(:values)
              end
              options[:name] ||= l(options[:label] || "field_#{field}".gsub(/_id$/, ''))
            end
          end
          @available_filters
        end
      end  
    end 
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end