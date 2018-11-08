module GroupedScope
  module Arish
    module Associations
      class AssociationScope < ActiveRecord::Associations::AssociationScope
        
        
        private
        
        # A direct copy of of ActiveRecord's AssociationScope#add_constraints. If this was 
        # in chunks, it would be easier to hook into. This more elegant version which supers
        # up will only work for the has_many. https://gist.github.com/1434980 
        # 
        # We will just have to monitor rails every now and then and update this. Thankfully this
        # copy is only used in a group scope. 

        def add_constraints(scope)
          tables = construct_tables

          chain.each_with_index do |reflection, i|
            table, foreign_table = tables.shift, tables.first

            if reflection.source_macro == :has_and_belongs_to_many
              join_table = tables.shift

              scope = scope.joins(join(
                                    join_table,
                                    table[reflection.association_primary_key].
                                      eq(join_table[reflection.association_foreign_key])
                                  ))

              table, foreign_table = join_table, tables.first
            end

            if reflection.source_macro == :belongs_to
              if reflection.options[:polymorphic]
                key = reflection.association_primary_key(self.klass)
              else
                key = reflection.association_primary_key
              end

              foreign_key = reflection.foreign_key
            else
              key         = reflection.foreign_key
              foreign_key = reflection.active_record_primary_key
            end

            if reflection == chain.last
              # GroupedScope changed this area.

              scope = if owner.group.present?
                        # binding.pry
                        #bind_val = bind scope, table.table_name, key.to_s, owner.group.ids_sql
                        scope.where(table[key].in(owner.group.ids_sql))
                      else
                        bind_val = bind scope, table.table_name, key.to_s, owner[foreign_key]
                        scope.where(table[key].eq(bind_val))
                      end

              if reflection.type
                value    = owner.class.base_class.name
                bind_val = bind scope, table.table_name, reflection.type.to_s, value
                scope    = scope.where(table[reflection.type].eq(bind_val))
              end
            else
              constraint = table[key].eq(foreign_table[foreign_key])

              if reflection.type
                type = chain[i + 1].klass.base_class.name
                constraint = constraint.and(table[reflection.type].eq(type))
              end

              scope = scope.joins(join(foreign_table, constraint))
            end

            is_first_chain = i == 0
            klass = is_first_chain ? self.klass : reflection.klass

            # Exclude the scope of the association itself, because that
            # was already merged in the #scope method.
            scope_chain[i].each do |scope_chain_item|
              item  = eval_scope(klass, scope_chain_item)

              if scope_chain_item == self.reflection.scope
                scope.merge! item.except(:where, :includes)
              end

              if is_first_chain
                scope.includes! item.includes_values
              end

              scope.where_values += item.where_values
              scope.order_values |= item.order_values
            end
          end

          scope
        end

      end
    end
  end
end
