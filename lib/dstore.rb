require 'yaml'

module Dstore
  class DB
    def initialize( config )
      @config = { :database => 'databases.yml', :index => 'indexs.yml', :namespace => 'dev' }.merge( config )
      if( @config[:database] and File.exist? @config[:database] )
        @tables = YAML.load( File.open( @config[:database], "r" ) )
      else
        @tables = {}
      end
      @indexs = {}
    end

    def create_table( tname, fields )
      @tables[tname] = fields
      save_schema
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
          entities.push( e )
        }
        AppEngine::Datastore.put entities 
      end
    end

    def delete_query( q )
      keys = []
      q.each{|e| 
        keys.push e.key 
      }
      AppEngine::Datastore.delete keys
    end

  end
  
end
