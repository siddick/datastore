
remove_file 'Gemfile'
create_file 'Gemfile' do
<<-GEMFILE

disable_system_gems
disable_rubygems
bundle_path ".gems/bundler_gems"

gem 'rails', '~> 3.0.3'
gem 'activerecord-datastore-adapter'

GEMFILE
end

remove_file 'config/boot.rb'
create_file 'config/boot.rb' do
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

File.class_eval do
  class << self
    alias :old_expand_path :expand_path
    def expand_path( *args )
      fn = old_expand_path( *args )
      fn.sub(/^.*file:/, 'file:') if fn
    end
  end
end

BOOT
end

remove_file 'config/database.yml'
create_file 'config/database.yml' do
<<-DATABASE
development:
  adapter: datastore
  database: development.yml

test:
  adapter: datastore
  database: test.yml

production:
  adapter: datastore
  database: development.yml
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

create_file 'config/initializers/cache_store.rb' do
<<-CACHE_STORE
#require 'appengine-apis/memcache'
#ActionController::Base.cache_store = AppEngine::Memcache.new
CACHE_STORE
end


system "appcfg.rb generate_app ."
