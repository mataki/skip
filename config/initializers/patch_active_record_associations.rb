module ActiveRecord
  module Associations # :nodoc:
    module ClassMethods
      private
        # Rails2.3.5で:fromオプションで指定したfrom句が使われるようにするため
        def construct_finder_sql_for_association_limiting(options, join_dependency)
          scope       = scope(:find)

          # Only join tables referenced in order or conditions since this is particularly slow on the pre-query.
          tables_from_conditions = conditions_tables(options)
          tables_from_order      = order_tables(options)
          all_tables             = tables_from_conditions + tables_from_order
          distinct_join_associations = all_tables.uniq.map{|table|
            join_dependency.joins_for_table_name(table)
          }.flatten.compact.uniq

          order = options[:order]
          if scoped_order = (scope && scope[:order])
            order = order ? "#{order}, #{scoped_order}" : scoped_order
          end

          is_distinct = !options[:joins].blank? || include_eager_conditions?(options, tables_from_conditions) || include_eager_order?(options, tables_from_order)
          sql = "SELECT "
          if is_distinct
            sql << connection.distinct("#{connection.quote_table_name table_name}.#{primary_key}", order)
          else
            sql << primary_key
          end
          sql << " FROM #{(scope && scope[:from]) || options[:from] || connection.quote_table_name(table_name)} "

          if is_distinct
            sql << distinct_join_associations.collect { |assoc| assoc.association_join }.join
            add_joins!(sql, options[:joins], scope)
          end

          add_conditions!(sql, options[:conditions], scope)
          add_group!(sql, options[:group], options[:having], scope)

          if order && is_distinct
            connection.add_order_by_for_association_limiting!(sql, :order => order)
          else
            add_order!(sql, options[:order], scope)
          end

          add_limit!(sql, options, scope)

          return sanitize_sql(sql)
        end
    end
  end
end
