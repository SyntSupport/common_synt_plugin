module CustomFieldsHelperPatch
  module ClassMethods
    
  end
  
  module InstanceMethods
    def self.included(receiver)
      receiver.class_eval do
        def custom_field_tag(name, custom_value)
          custom_field = custom_value.custom_field
          field_name = "#{name}[custom_field_values][#{custom_field.id}]"
          field_name << "[]" if custom_field.multiple?
          field_id = "#{name}_custom_field_values_#{custom_field.id}"

          tag_options = {:id => field_id, :class => "#{custom_field.field_format}_cf"}

          if (custom_field.id == 9)
            cust_field = CustomValue.find(:first, :conditions => "customized_id = #{@project.id} and custom_field_id = '10'")
            if !cust_field.nil?      
              blank_option = custom_field.is_required? ?
                               (custom_field.default_value.blank? ? "<option value=\"\">--- #{l(:actionview_instancetag_blank_option)} ---</option>" : '') :
                               '<option></option>'
              return select_tag(field_name, raw(blank_option + options_for_select(cust_field.to_s.split(';'),
                      custom_value.value)), :id => field_id)
            end
          end

          field_format = Redmine::CustomFieldFormat.find_by_name(custom_field.field_format)
          case field_format.try(:edit_as)
          when "date"
            text_field_tag(field_name, custom_value.value, tag_options.merge(:size => 10)) +
            calendar_for(field_id)
          when "text"
            text_area_tag(field_name, custom_value.value, tag_options.merge(:rows => 3))
          when "bool"
            hidden_field_tag(field_name, '0') + check_box_tag(field_name, '1', custom_value.true?, tag_options)
          when "list"
            blank_option = ''.html_safe
            unless custom_field.multiple?
              if custom_field.is_required?
                unless custom_field.default_value.present?
                  blank_option = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '')
                end
              else
                blank_option = content_tag('option')
              end
            end
            s = select_tag(field_name, blank_option + options_for_select(custom_field.possible_values_options(custom_value.customized), custom_value.value),
              tag_options.merge(:multiple => custom_field.multiple?))
            if custom_field.multiple?
              s << hidden_field_tag(field_name, '')
            end
            s
          else
            text_field_tag(field_name, custom_value.value, tag_options)
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