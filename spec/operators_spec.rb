require 'spec_helper'

describe Person do
  before :each do
    AppEngine::Testing.install_test_datastore
  end

  it " in operator" do
    Person.create!( :name => "guest" )
    people = Person.where( " created_at <= ? ", Time.now + 1 )
    people.all.size.should_not == 0

    people = Person.where( :name => [ "guest", "not_guest" ] )
    people.all.size.should == 1

    people = Person.where( " name in('guest','not_guest')" )
    people.all.size.should == 1

    people = Person.where( " name in( 'guest', 'not_guest' )" )
    people.all.size.should == 1

    people = Person.where( "( name in( 'guest', 'not_guest' ) )" )
    people.all.size.should == 1

    people = Person.where( "(name in( 'guest', 'not_guest' ))" )
    people.all.size.should == 1
  end

end
