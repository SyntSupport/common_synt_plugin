module UserPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      # run code for updating issue
      #alias_method_chain :before_save, :pass_check
      before_save   :before_save_with_pass_check
    end
  end

  module ClassMethods
    #Создание пользователей по заданной почте
    #Return: массив ошибок, массив ид пользователей
    #IN: mails - строка почт, разделенных запятой, точкой с запятой, пробелами
    #    project_id - ид проекта
    def create_users_by_mails(mails,project_id)
      begin
        #добавлять пользователя и назначать его клиентом проекта
        #custom_field_id = '11' - это настаиваемое значение для проекта !!!!НАДО ПОМЕНЯТЬ, ЕСЛИ ДРУГОЙ ИД!!!!
        mail_patterns = CustomValue.find(:first, :conditions => "customized_id = #{project_id} and custom_field_id = '11'")
        mail_patterns = (mail_patterns.value.split(/[,;\s]/).uniq.delete_if(&:empty?) if not mail_patterns.nil?) || []
        mails = mails.split(/[,;\s]/).uniq.delete_if(&:empty?)
        ids = []
        mail_errors = []
        mails.each do |mail|
          if mail =~ /syntellect.ru$/i
            logger.info 'user.errors'
            mail_errors << (l(:not_valid_mail) + ": " + mail)
            next
          end
          #проверка на соответствие шаблону
          ispatterned = false
          mail_patterns.each do |patt|
            if mail.match(Regexp.new(patt,Regexp::IGNORECASE))
              ispatterned = true
            end
          end
          if not mail_patterns.blank? and ispatterned == false
            mail_errors << (l(:wrong_domain) + ": " + mail)
            next
          end
          #длина мыла не больше 50 символов
          if mail.length > 50
            logger.info 'user.errors'
            mail_errors << (l(:mail_too_long) + ": " + mail)
            next
          end
          if fuser = User.find_by_mail(mail)
            #добавление юзера в клиенты проекта, если его нет
            if fuser.memberships.collect(&:project).compact.uniq.select{|item| item.id == project_id}.blank?
              membership = Member.edit_membership(nil, ({"role_ids"=>["6"]}).merge(:project_id => project_id), fuser)
              membership.save
            end
            ids << fuser.id.to_s
          else
            logger.info 'user.new'
            #создание пользователя
            user_params = {:firstname=> mail, :lastname=>"not_user", :mail=> mail, :language=>"ru", :admin=>"0", :mail_notification=>"only_my_events"}
            pref = {:hide_mail=>"0", :time_zone=>"", :comments_sorting=>"asc", :warn_on_leaving_unsaved=>"1"}
            user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
            user.attributes = user_params
            user.admin = false
            user.login = mail
            #user.password, user.password_confirmation = user_params[:password], user_params[:password_confirmation]

            user.pref.attributes = pref
            user.pref[:no_self_notified] = true

            begin
              if user.save
                logger.info 'user.save'
                user.pref.save
                #добавление юзера в клиенты проекта
                membership = Member.edit_membership(nil, ({"role_ids"=>["6"]}).merge(:project_id => project_id), user)
                membership.save
                ids << user.id.to_s
              else
                logger.info 'user.errors'
                user.errors.full_messages.each do |message|
                  mail_errors << (message + ": " + mail)
                end
              end
            rescue Exception => exp
              logger.info 'RESCUE SECTION 1'
              logger.info exp.inspect
              mail_errors << (l(:not_valid_mail) + ": " + mail)
            end
          end
        end
      rescue Exception => exp
        logger.info 'RESCUE SECTION 2'
        logger.info exp.inspect
      end
      return mail_errors, ids
    end
  end

  module InstanceMethods
    def self.included(base)
      base.class_eval do
        def name(formatter = nil)
          if !User.current.client? || self.client?
            f = self.class.name_formatter(formatter)
            if formatter
              eval('"' + f[:string] + '"')
            else
              @name ||= eval('"' + f[:string] + '"')
            end
          else 
            "Syntellect"
          end
        end

        def client?
          if @isclient.nil?
           @isclient = !self.allowed_to?(:see_real_names, @project, :global => true)
          end
          return @isclient
        end

        def to_s
          name.slice!(" not_user")
          name
        end
      end
    end


    def before_save_with_pass_check
        if self.password_confirmation
          if self.password.match(/^#{self.login}/)
            self.errors[:base] << l(:message_your_pass, :log => l(:start_with_name))
            return false
          end
          isstrongenough, strlog = strong_enough_pass(self.password)
          if !isstrongenough
            self.errors[:base] << (l(:message_your_pass, :log => strlog)[0..-3])
            return false
          end
        end
    end

    def strong_enough_pass (passwd)
        strlog = ""
        ret = true
        unless (/[a-z]/.match passwd)                              # [verified] at least one lower case letter
          strlog   = strlog + l(:no_lowercase) + ", "
          ret = false
        end

        unless (/[A-Z]/.match passwd)                              # [verified] at least one upper case letter
          strlog   = strlog + l(:no_capital) + ", "
          ret = false
        end

        # NUMBERS
        unless (/\d+/.match passwd)                                 # [verified] at least one number
          strlog   = strlog + l(:no_numbers) + ", "
          ret = false
        end

        # SPECIAL CHAR
        unless (/[\!,\@,\#,\$,\%,\^,\&,\*,\?,\_,\~,\(,\),\[,\],\{,\},\<,\,,\>,\.,\|,\',\",\:,\\,\/,\;]/.match passwd)             # [verified] at least one spec
          strlog   = strlog + l(:no_spec) + ", "
          ret = false
        end
        return ret, strlog
    end
  end
end