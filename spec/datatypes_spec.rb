require 'spec_helper'

class User < ActiveRecord::Base

  validates_uniqueness_of :name

  connection.create_table table_name, :force => true do |t|
    t.string      :name,  :limit => 25
    t.datetime    :dob
    t.integer     :rating
    t.float       :score
    t.binary      :data

    t.timestamps
  end
end

describe Person do

  before :each do
    AppEngine::Testing.install_test_datastore
  end

  it "time object" do
    name = "guest"
    dob  = Time.now
    user = User.create!( :name => "guest", :dob => dob )
    user.dob.should == dob

    user = User.first
    user.dob.should == dob

    user = User.find_by_dob( dob )
    user.dob.should == dob
  end

  it "rating object" do
    5.times{|i|
      User.create!( :name => "guest#{i}", :rating => i )
    }
    users = User.where( " rating >= 1 and rating <= 3 " )
    users.all.size.should == 3
  end

  it "check integer" do
    user = User.create!( :name => "guest", :rating => "5a" )
    user = User.find( user.id )
    user.rating.should == 5
  end

  it "check datetime" do
    user = User.create!( :name => "guest", :dob => "24 may, 2010" )
    user = User.find( user.id )
    user.dob.strftime("%Y-%m-%d").should == "2010-05-24"
  end
  
  it "check binary" do
    user = User.create!( :name => "guest", :dob => "24 may, 2010", :data => "testing" )
    user.data.class.should == AppEngine::Datastore::Blob
    user = User.find_by_name( "guest" )
    user.data.should == "testing"
    user.data.class.should == AppEngine::Datastore::Blob
  end
end
