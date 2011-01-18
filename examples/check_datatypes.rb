require 'active_record'
require 'logger'


ActiveRecord::Base.logger = Logger.new( STDERR )

class User < ActiveRecord::Base
  establish_connection :adapter => 'datastore', :database => 'database.yml', :index => 'indexs.yml'

  connection.create_table table_name, :force => true do |t|
    t.string    :name
    t.integer   :age
    t.datetime  :dob
    t.float     :score
    f.text      :data

    t.timestamps
  end
end

u = User.create!( :name => "nothing", :age => 7, :dob => Time.now, :score => 90.5 )
