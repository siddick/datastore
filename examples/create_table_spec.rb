
$LOAD_PATH.push( File.join( File.dirname( __FILE__ ), '..', 'lib' ) )
require 'active_record'
require 'logger'


ActiveRecord::Base.logger = Logger.new( STDERR )

class Person < ActiveRecord::Base
  establish_connection :adapter => 'datastore', :database => 'database.yml', :index => 'indexs.yml'

  has_many :person_roles, :dependent => :destroy
  has_many :roles, :through => :person_roles

  connection.create_table table_name, :force => true do |t|
    t.string :name
    t.string :description
    t.text    :data
  end
end

class Role < ActiveRecord::Base
  establish_connection :adapter => 'datastore', :database => 'database.yml', :index => 'indexs.yml'
  has_many :person_roles, :dependent => :destroy
  has_many :people, :through => :person_roles

  connection.create_table table_name, :force => true do |t|
    t.string :name
  end
end

class PersonRole < ActiveRecord::Base
  establish_connection :adapter => 'datastore', :database => 'database.yml', :index => 'indexs.yml'
  belongs_to :person
  belongs_to :role


  connection.create_table table_name, :force => true do |t|
    t.integer :person_id
    t.integer :role_id
  end

  connection.add_index table_name, [ :person_id, :role_id ]
end



Person.destroy_all
Role.destroy_all

Person.create!( :name => "guest", :description => "for example" )

p = Person.where( :name => "guest" , :description => "for example" ).first
p = Person.find_by_name_and_description( "guest" , "for example" )

p.roles.build( :name => "guest" )
p.save
puts Person.order("name").all.inspect
puts Role.all.inspect
puts PersonRole.all.inspect
