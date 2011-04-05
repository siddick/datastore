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
        attr :connection

        def initialize( conn, kind, options = {} )
          @connection = conn
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

        def wheres( conditions )
          conditions.each{|w|
            w_expr  = w.expr rescue w
            if( w_expr.class != Arel::Nodes::SqlLiteral )
              key     = w_expr.left.name
              val     = w_expr.right
              opt     = w_expr.operator
              apply_filter( key, opt, val )
            else
              parese_expression_string( w_expr.to_s )
            end
          }
          self
        end

        TypeCast = {
          :primary_key => lambda{|k,v| AppEngine::Datastore::Key.from_path( k, v.to_i ) },
          :integer     => lambda{|k,i| i.to_i },
          :datetime    => lambda{|k,t| t.is_a?(Time)? t : Time.parse(t.to_s) },
          :date        => lambda{|k,t| t.is_a?(Date)? t : Date.parse(t.to_s) },
          :float       => lambda{|k,f| f.to_f }
        }
        InScan = /'((\\.|[^'])*)'|(\d+)/
        def apply_filter( key, opt, value )
          key, opt = key.to_sym, opt.to_sym
          column = @connection.columns(kind).find{|c| c.name == key.to_s }
          opt = :in      if value.is_a? Array
          type_cast_proc = TypeCast[ column.primary ? :primary_key : column.type ]
          if opt == :in or opt == :IN
            value = value.scan(InScan).collect{|d| d.find{|i| i}}   if value.is_a? String
            value.collect!{|v| type_cast_proc.call(kind,v) }        if type_cast_proc
            options[:empty], value = true, [ "EMPTY" ]              if value.empty?
          else
            value = type_cast_proc.call( kind, value ) if type_cast_proc
          end
          key = :__key__ if column.primary
          q.filter( key, opt, value )
        end

        
        RExpr = Regexp.union( /(in)/i,
                     /\(\s*(('((\\.|[^'])*)'|\d+)(\s*,\s*('((\\.|[^'])*)'|\d+))*)\s*\)/,
                     /"((\\.|[^"])*)"/,
                     /'((\\.|[^'])*)'/,
                     /([\w\.]+)/,
                     /([^\w\s\.'"]+)/ )
        Optr      = { "=" => :== }
        ExOptr    = ["(",")"]
        def parese_expression_string( query )
          datas = query.scan( RExpr ).collect{|a| a.find{|i| i } }
          datas.delete_if{|d| ExOptr.include?(d) }
          while( datas.size >= 3 )
            key = datas.shift.sub(/^[^.]*\./,'').to_sym
            opt = datas.shift
            val = datas.shift
            concat_opt = datas.shift
            apply_filter( key, Optr[opt] || opt.to_sym, val )
          end
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
        QString.new( @connection, c.froms.name, get_limit_and_offset(o) ).wheres( c.wheres ).orders(o.orders).projections( c.projections )
      end

      def visit_Arel_Nodes_InsertStatement o
        e = AppEngine::Datastore::Entity.new(o.relation.name)
        o.columns.each_with_index{|c,i| e[c.name] = o.values.left[i] }
        e
      end

      def visit_Arel_Nodes_UpdateStatement o
        QString.new( @connection, o.relation.name, :values => o.values.collect{|v| [ v.left.name, v.right ] } ).wheres( o.wheres )
      end

      def visit_Arel_Nodes_DeleteStatement o
        QString.new( @connection, o.relation.name ).wheres( o.wheres )
      end

    end
  end
end

Arel::Visitors::VISITORS['datastore'] = Arel::Visitors::Datastore
