module GroupedScope
  module HasManyAssociation
    
    def self.included(klass)
      klass.class_eval do
        alias_method_chain :construct_sql, :group_scope
      end
    end
    
    def construct_sql_with_group_scope
      if @reflection.options[:grouped_scope]
        if @reflection.options[:as]
          # TODO: Need to add case for polymorphic :as option.
          # @finder_sql = 
          #   "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_id = #{@owner.quoted_id} AND " +
          #   "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_type = #{@owner.class.quote_value(@owner.class.base_class.name.to_s)}"
          # @finder_sql << " AND (#{conditions})" if conditions
        else
          @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} IN (#{@owner.group.quoted_ids})"
          @finder_sql << " AND (#{conditions})" if conditions
        end
        @counter_sql = @finder_sql
      else
        construct_sql_without_group_scope
      end
    end
    
    
  end
end

ActiveRecord::Associations::HasManyAssociation.send :include, GroupedScope::HasManyAssociation
