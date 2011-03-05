require 'arel'
require 'arel/visitors'
require 'arel/visitors/to_sql'
require 'appengine-apis/datastore'

module Arel
  module Visitors
    class Datastore < Arel::Visitors::ToSql

      class QString
        attr :kind
        attr :q 
        attr :options

        def initialize( kind, options = {} )
          @kind = kind
          @q = AppEngine::Datastore::Query.new( kind )
          @options = options
        end

        def to_s
          out = q.inspect 
          out += " OFFSET #{options[:offset]} " if options[:offset]  
          out += " LIMIT  #{options[:limit]} "  if options[:limit]  
          out
        end

        alias :inspect :to_s

        def projections( projs )
          projs.each{|p|
            if( p.is_a? Arel::Nodes::Count )
              options[:count] = true
            end
          }
          self
        end

        def where( wheres )
          wheres.each{|w|
            w_expr  = w.expr
            if( w_expr.class != Arel::Nodes::SqlLiteral )
              key     = w_expr.left.name == :id ? :__key__ : w_expr.left.name
              val     = w_expr.right
              opt     = val.class == Array ? :in : w_expr.operator
              if( opt == :in and val.empty? )
                options[:empty] = true 
                val = [ "EMPTY" ]
              end

              if( key == :__key__ )
                if opt == :in
                  val = val.collect{|v| AppEngine::Datastore::Key.from_path( kind, v.to_i ) } 
                else
                  val =  AppEngine::Datastore::Key.from_path( kind, val.to_i )
                end
              end
              q.filter( key, opt, val )
            end
          }
          self
        end
        def orders( ords )
          ords.each{|o|
            if( o.is_a? String )
              key, dir, notuse = o.split
            else
              key, dir = o.expr, o.direction
            end
            q.sort( key, dir )
          }
          self
        end
      end

      def get_limit_and_offset( o )
        options = {}
        options[:limit]  = o.limit.expr if o.limit
        options[:offset] = o.offset.expr if o.offset
        options
      end

      def visit_Arel_Nodes_SelectStatement o
        c    = o.cores.first
        QString.new( c.froms.name, get_limit_and_offset(o) ).where( c.wheres ).orders(o.orders).projections( c.projections )
      end

      def visit_Arel_Nodes_InsertStatement o
        e = AppEngine::Datastore::Entity.new(o.relation.name)
        o.columns.each_with_index{|c,i| e[c.name] = o.values.left[i] }
        e
      end

      def visit_Arel_Nodes_UpdateStatement o
        QString.new( o.relation.name, :values => o.values.collect{|v| [ v.left.name, v.right ] } ).where( o.wheres )
      end

      def visit_Arel_Nodes_DeleteStatement o
        QString.new( o.relation.name ).where( o.wheres )
      end

    end
  end
end

Arel::Visitors::VISITORS['datastore'] = Arel::Visitors::Datastore
