require 'active_record/connection_adapters/abstract_adapter'
require 'active_support/core_ext/kernel/requires'
require 'active_support/core_ext/object/blank'
require 'set'

require 'yaml'
require 'arel/visitors/datastore'

module ActiveRecord
  class Base
    def self.datastore_connection(config) # :nodoc:
      ConnectionAdapters::DatastoreAdapter.new( ConnectionAdapters::DatastoreAdapter::DB.new( config.symbolize_keys ), logger )
    end
  end

  module ConnectionAdapters
    class DatastoreAdapter < AbstractAdapter
      ADAPTER_NAME = "Datastore"

      def adapter_name #:nodoc:
        ADAPTER_NAME
      end
      
      def supports_migrations? #:nodoc:
        true
      end

      def supports_primary_key? #:nodoc:
        true
      end

      def supports_autoincrement? #:nodoc:
        true
      end

      def native_database_types #:nodoc:
        {
          :primary_key => { :name => "integer", :primary_key => true },
          :string      => { :name => "varchar", :limit => 255 },
          :text        => { :name => "text" },
          :integer     => { :name => "integer" },
          :float       => { :name => "float" },
          :decimal     => { :name => "decimal" },
          :datetime    => { :name => "datetime" },
          :timestamp   => { :name => "datetime" },
          :time        => { :name => "time" },
          :date        => { :name => "date" },
          :binary      => { :name => "blob" },
          :boolean     => { :name => "boolean" }
        }
      end

      def select( sql, name = nil, binds = [] )
        log( sql.inspect, name ) {
          @connection.select_query( sql.q, sql.options )
        }
      end

      def insert(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        log( "Insert: " + sql.inspect, name ){
          @connection.insert_query( sql )
        }
      end

      def update( sql, name = nil)
        log( "Update: VALUES(#{sql.options[:values].collect{|k,v|k.to_s + " = " + v.inspect}.join(", ")}) " + sql.inspect, name ) {
          @connection.update_query( sql.q, sql.options[:values] )
        }
      end
      
      def delete(sql, name = nil)
        log( "Delete: " + sql.inspect, name ) {
          @connection.delete_query( sql.q )
        }
      end


      def execute(sql, name = nil)
        log("Not Support: " + sql, name) {
          #@connection.execute( sql )
        } 
      end

      def create_table( table_name, options = {} )
        log( "CREATE TABLE #{table_name}", "Datastore Adapter" ) {
          td = TableDefinition.new(self)
          td.primary_key(options[:primary_key] || Base.get_primary_key(table_name.to_s.singularize)) unless options[:id] == false

          yield td if block_given?

          fields = {}
          td.columns.each{|c| fields[c.name.to_s] = { :default => c.default, :type => c.type.to_s, :null => c.null } }
          @connection.create_table( table_name, fields )
          td
        }
      end

      def tables
        @connection.tables.keys
      end

      def columns( table_name, name = nil)
        @connection.columns( table_name, name ).collect{|k,opt|
          Column.new( k, opt[:default], opt[:type] == :primary_key ? "integer" : opt[:type].to_s, opt[:null] )
        } 
      end
      
      def primary_key( table_name )
        'id'
      end

      class DB
        def initialize( config )
          @config = { :database => 'database.yaml', :index => 'index.yaml', :namespace => 'dev' }.merge( config )
          if( @config[:database] and File.exist? @config[:database] )
            @tables = YAML.load( File.open( @config[:database], "r" ) )
          else
            @tables = {}
          end

          if( @config[:index] and File.exist? @config[:index] )
            @indexes = YAML.load( File.open( @config[:index], "r" ) )
            @indexes = @indexes[:indexes] || []
          else
            @indexes = []
          end
        end

        def create_table( tname, fields )
          @tables[tname] = fields
          save_schema
        end

        def drop_table( tname, options = {} )
          @tables.delete(tname)
          save_schema
        end

        def rename_table( tname, ntname )
          value = @tables.delete(tname)
          if( value )
            @tables[ntname] = value 
            save_schema
          end
        end

        def add_column(table_name, column_name, type, options = {})
          @tables[table_name][column_name] = { :type => type.to_s, :default => options[:default], :null => options[:null] }
          save_schema
        end

        alias :change_column :add_column

        def add_index(table_name, column_name, options = {})
          table_name  = table_name.to_s
          column_name = [ column_name ] unless column_name.is_a? Array
          column_name.map!{|c| c.to_s }
          inds = @indexes.find_all{|i| i["kind"] == table_name and i["properties"].map{|p| p["name"] } == column_name }
          unless inds.empty?
            @indexes.push( { "kind" => table_name, "properties" => column_name.map{|c| { "name" => c } } } )
            save_indexes
          end
        end

        def remove_index(table_name, column_name )
          column_name = column_name[:column] if column_name.is_a? Hash
          column_name = [ column_name ] unless column_name.is_a? Array
          column_name.map!{|c| c.to_s }
          inds = @indexes.delete_all{|i| i["kind"] == table_name and i["properties"].map{|p| p["name"] } == column_name }
          save_indexes
        end

        def save_indexes
          f = File.open( @config[:index], 'w' )
          f.write( { "indexes" => @indexes }.to_yaml )
          f.close
        end

        def save_schema
          f = File.open( @config[:database], 'w' )
          f.write( @tables.to_yaml )
          f.close
        end
        
        def tables
          @tables
        end

        def columns( table_name, name = nil )
          if tables[table_name]
            tables[table_name]
          end
        end

        def primary_key( tname )
          'id'
        end

        def select_query( q, options = {} )
          output = []
          if( options[:empty] )
            []
          elsif( options[:count] )
            output.push( { "count" => q.count() } )
          else
            t_name = q.kind
            p_key  = primary_key( t_name )
            column_list = columns( t_name )  
            q.fetch(options).each{|e| 
              h = {}
              column_list.each{|n,opt|
                h[n] = ( n == p_key ? e.key.id : e[n] )
              }
              output.push( h )
            }
          end
          output
        end

        def insert_query( q )
          AppEngine::Datastore.put q
          q.key.id
        end

        def update_query( q, values = nil )
          if( values and values.size > 0 )
            entities = []
            q.each{|e|
              values.each{|k,v| e[k] = v }
              entities.push(e)
            }
            AppEngine::Datastore.put entities 
          end
        end

        def delete_query( q )
          keys = []
          q.each{|e| keys.push e.key }
          AppEngine::Datastore.delete keys
        end
      end

    end
  end
end


require 'active_record/associations'
require 'active_record/associations/has_many_association'
require 'active_record/associations/has_many_through_association'

ActiveRecord::Associations::HasManyAssociation.class_eval do
  def owner_id
    if @reflection.options[:primary_key]
      @owner.send(@reflection.options[:primary_key])
    else
      @owner.id
    end
  end

  def construct_sql
    case
    when @reflection.options[:finder_sql]
      @finder_sql = interpolate_sql(@reflection.options[:finder_sql])
    when @reflection.options[:as]
      @finder_sql = { ( @reflection.options[:as]+ "_id" ) => owner_id,
        ( @reflection.options[:as] + "_type" ) => @owner.class.quote_value(@owner.class.base_class.name.to_s) }
      @finder_sql.merge!( conditions ) if conditions
    else
      @finder_sql = { @reflection.primary_key_name => owner_id }
      @finder_sql.merge!( conditions ) if conditions
    end

    construct_counter_sql
  end
end

ActiveRecord::Associations::HasManyThroughAssociation.class_eval do

  def owner_id
    if @reflection.options[:primary_key]
      @owner.send(@reflection.options[:primary_key])
    else
      @owner.id
    end
  end


  def construct_conditions
    if @reflection.source_reflection.macro == :belongs_to
      source_primary_key = @reflection.source_reflection.primary_key_name
    else
      source_primary_key = @reflection.through_reflection.klass.primary_key
    end
    ids = @owner.send(@reflection.options[:through]).map{|t| t.send(source_primary_key) }
    conditions = { :id => ids }
  end


  def construct_scope
    { :create => construct_owner_attributes(@reflection),
      :find   => { :conditions  => construct_conditions,
#        :joins       => construct_joins,
        :include     => @reflection.options[:include] || @reflection.source_reflection.options[:include],
        :select      => construct_select,
        :order       => @reflection.options[:order],
        :limit       => @reflection.options[:limit],
        :readonly    => @reflection.options[:readonly],
    } }
  end

end
