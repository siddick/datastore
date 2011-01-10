require 'yaml'

module Dstore
  # Your code goes here...
  class DB
    def initialize( config )
      @config = { :database => 'databases.yml', :index => 'indexs.yml', :namespace => 'dev' }.merge( config )
      if( @config[:database] and File.exist? @config[:database] )
        @tables = YAML.load( @config[:database] )
      else
        @tables = {}
      end
      @indexs = {}
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
        tables[table_name].columns
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
        column_list.each{|c|
          h[c.name.to_s] = ( c.name == p_key ? e.key.id : e[c.name] )
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
        q.each{|e| 
          values.each{|k,v| e[k] = v }
          AppEngine::Datastore.put e
        }
      end
    end

    def delete_query( q )
      q.each{|e| 
        AppEngine::Datastore.delete e.key
      }
    end

  end
  
end
