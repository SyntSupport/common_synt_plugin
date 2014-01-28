module MailerPatch
  module ClassMethods
    
  end
  
  module InstanceMethods
    def self.included(receiver)
      receiver.class_eval do
        def self.deliver_issue_edit(journal)
          issue = journal.journalized.reload
          to = journal.notified_users
          cc = journal.notified_watchers
          journal.each_notification(to + cc) do |users|
            issue.each_notification(users) do |users2|
              [users2.select{|x| !x.client? }].collect do |workers|
                Mailer.issue_edit(journal, workers, []).deliver
              end
              [users2.select{|x| x.client? }].collect do |clients|
                curr_user = User.current
                User.current= clients.first
                Mailer.issue_edit(journal, clients, []).deliver
                User.current= curr_user
              end
            end
          end
        end

        def self.deliver_issue_add(issue)
          to = issue.notified_users
          cc = issue.notified_watchers - to
          issue.each_notification(to + cc) do |users|
            [users.select{|x| !x.client? }].collect do |workers|
              Mailer.issue_add(issue, workers, []).deliver
            end
            [users.select{|x| x.client? }].collect do |clients|
              curr_user = User.current
              User.current= clients.first
              Mailer.issue_add(issue, clients, []).deliver
              User.current= curr_user
            end
            
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