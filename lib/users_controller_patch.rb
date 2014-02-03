module UsersControllerPatch
  module ClassMethods
    
  end
  
  module InstanceMethods
    def self.included(receiver)
      receiver.class_eval do
        # not to allow a customer to browse a worker profile page
        def show
          # show projects based on current user visibility
          @memberships = @user.memberships.where(Project.visible_condition(User.current)).all

          events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
          @events_by_day = events.group_by(&:event_date)

          unless User.current.admin?
            if !@user.active? || (@user != User.current  && @memberships.empty? && events.empty?) ||
                 (User.current.client? && ! @user.client?)
              render_404
              return
            end
          end

          respond_to do |format|
            format.html { render :layout => 'base' }
            format.api
          end
        end
      end
    end 
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end