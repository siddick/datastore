
remove_file 'Gemfile'
create_file 'Gemfile' do
<<-GEMFILE

disable_system_gems
disable_rubygems
bundle_path ".gems/bundler_gems"

gem 'rails', '3.0.6'
gem 'activerecord-datastore-adapter', :git => 'git://github.com/siddick/datastore.git'
gem 'jruby-rack', '1.0.5'

GEMFILE
end

gsub_file 'config/boot.rb', /^/ do
  "# "
end

remove_file 'config/database.yml'
create_file 'config/database.yml' do
<<-DATABASE
development:
  adapter: datastore
  database: db/database.yml

test:
  adapter: datastore
  database: db/test.yml

production:
  adapter: datastore
  database: db/database.yml
DATABASE
end

gsub_file 'config/application.rb', /Bundler/ do
    "# Bundler"
end

gsub_file 'config/application.rb', /class Application < Rails::Application$/ do
  "class Application < Rails::Application
      require 'appengine-apis/logger'
      config.logger = AppEngine::Logger.new
  "
end

create_file 'config/initializers/rails_patch.rb' do
<<-BOOT

String.class_eval do
  alias :old_plus :+
  def +( val )
    if( val.is_a? Array )
      [ self ] + val
    else
      old_plus val
    end
  end
end
BOOT
end

create_file 'config/initializers/cache_store.rb' do
<<-CACHE_STORE
#require 'appengine-apis/memcache'
#ActionController::Base.cache_store = AppEngine::Memcache.new
CACHE_STORE
end


system "appcfg.rb generate_app ."
