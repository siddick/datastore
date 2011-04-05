class Person < ActiveRecord::Base
  has_many :person_roles, :dependent => :destroy
  has_many :roles, :through => :person_roles

  validates_uniqueness_of :name

  connection.create_table table_name, :force => true do |t|
    t.string :name
    t.string :description
    t.text   :data

    t.timestamps
  end
end

class Role < ActiveRecord::Base
  has_many :person_roles, :dependent => :destroy
  has_many :people, :through => :person_roles

  connection.create_table table_name, :force => true do |t|
    t.string :name

    t.timestamps
  end
end

class PersonRole < ActiveRecord::Base
  belongs_to :person
  belongs_to :role


  connection.create_table table_name, :force => true do |t|
    t.integer :person_id
    t.integer :role_id

    t.timestamps
  end

  connection.add_index table_name, [ :person_id, :role_id ]
end
