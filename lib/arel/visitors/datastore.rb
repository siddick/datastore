require 'arel'
require 'arel/visitors'
require 'arel/visitors/to_sql'
require 'appengine-apis/datastore'

module Arel
  module Visitors
    class Datastore < Arel::Visitors::ToSql

      class QString
        attr :q 
        attr :options

        def initialize( q, options = {} )
          @q = q
          @options = options
        end

        def to_s
          out = q.inspect 
          out += " OFFSET #{options[:offset]} " if options[:offset]  
          out += " LIMIT  #{options[:limit]} "  if options[:limit]  
          out
        end

        alias :inspect :to_s

        def self.generate( kind, wheres, options = {} )
          q = AppEngine::Datastore::Query.new( kind )
          wheres.each{|w|
            w_expr  = w.expr
            STDERR.puts "Where Expression: #{w_expr.inspect}(#{w_expr.class.inspect})"
            if( w_expr.class != Arel::Nodes::SqlLiteral )
              key     = w_expr.left.name
              val     = w_expr.right
              opt     = val.class == Array ? :in : w_expr.operator
              if( key == :id )
                key = :__key__
                if opt == :in
                  val = val.collect{|v| AppEngine::Datastore::Key.from_path( kind, v ) } 
                else
                  val =  AppEngine::Datastore::Key.from_path( kind, val )
                end
              end
              q.filter( key, opt, val )
            end
          }
          self.new( q, options )
        end

      end

      def visit_Arel_Nodes_SelectStatement o
        c    = o.cores.first
        QString.generate( c.froms.name, c.wheres, { :limit => o.limit, :offset => o.offset } )
      end

      def visit_Arel_Nodes_InsertStatement o
        e = AppEngine::Datastore::Entity.new(o.relation.name)
        o.columns.each_with_index{|c,i| e[c.name] = o.values.left[i] }
        e
      end

      def visit_Arel_Nodes_UpdateStatement o
        QString.generate( o.relation.name, o.wheres, :values => o.values.collect{|v| [ v.left.name, v.right ] } )
      end

      def visit_Arel_Nodes_DeleteStatement o
        QString.generate( o.relation.name, o.wheres )
      end

    end
  end
end

Arel::Visitors::VISITORS['datastore'] = Arel::Visitors::Datastore
