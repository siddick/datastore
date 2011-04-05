require 'spec_helper'


describe AppEngine::Datastore do
  Datastore = AppEngine::Datastore
  
  before :each do
    AppEngine::Testing.install_test_datastore
  end

  it "should support get/put" do

  end

end
