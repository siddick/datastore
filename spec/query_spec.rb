require 'spec_helper'


describe Person do
  before :each do
    AppEngine::Testing.install_test_datastore
  end

  it "init record" do
    person_name = "guest"
    person = Person.new( :name => person_name )
    person.id.should == nil
    person.name.should == person_name
  end

  it "save record" do
    person_name = "guest"
    person = Person.new( :name => person_name )
    person.save.should == true
  end

  it "record have id" do
    person_name = "guest"
    person = Person.new( :name => person_name )
    person.save.should == true
    person.id.should_not  == nil
  end

  it "retrive the record by id" do
    person_name = "guest"
    person = Person.new( :name => person_name )
    person.save
    find_person = Person.find( person.id )
    find_person.name.should == person_name
  end

  it "retrive the record by name" do
    person_name = "guest"
    person = Person.new( :name => person_name )
    person.save
    find_person = Person.find_by_name( person_name )
    find_person.name.should == person_name
  end

  it "retrive the record by name and description" do
    person_name = "guest"
    person_description = "description"
    Person.create!( :name => person_name, :description => person_description )
    find_person = Person.where( :name => person_name, :description => person_description ).first
    find_person.name.should == person_name
    find_person.description.should == person_description
  end

  it "update the record" do
    person_name     = "guest"
    new_person_name = "new_guest"
    person = Person.create!( :name => person_name )
    person.name.should        == person_name

    person.update_attributes( :name => new_person_name ).should == true
    person.name.should  == new_person_name

    person = Person.find_by_name( new_person_name )
    person.name.should  == new_person_name 
  end

  it "destroy the record" do
    person_name = "guest"
    person = Person.create!( :name => person_name )
    person.should_not == nil

    person = Person.find_by_name( person_name )
    person.should_not == nil

    person.destroy

    person = Person.find_by_name( person_name )
    person.should == nil
  end

end
