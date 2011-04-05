require 'spec_helper'

describe Person do
  before :each do
    AppEngine::Testing.install_test_datastore
  end

  it "create person on role" do
    person = Person.create!( :name => "guest" )
    role   = Role.create!( :name => "guest" )
    person.roles.push( role )

    person.save.should == true

    person = Person.find_by_name( "guest" )
    person.roles.size.should == 1

    role   = Role.find_by_name( "guest" )
    role.people.size.should == 1

    person.roles.build( :name => "admin" )
    person.save.should == true

    person = Person.find_by_name( "guest" )
    person.roles.size.should == 2

    Role.all.size.should == 2
    PersonRole.all.size.should == 2

    person = Person.find_by_name( "guest" )
    person.destroy

    PersonRole.all.size.should == 0
    Person.all.size.should == 0
    Role.all.size.should == 2
  end

end
