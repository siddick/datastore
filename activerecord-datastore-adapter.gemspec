# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "activerecord-datastore-adapter"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mohammed Siddick"]
  s.email       = ["siddick@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/datastore"
  s.summary     = %q{ActiveRecord Adapter for Appengine Datastore}
  s.description = %q{Just an ActiveRecord Adapter for the Appengine Datastore. 
    Create Rails3 application: rails new app_name -m http://siddick.github.com/datastore/rails3.rb}

  s.rubyforge_project = "activerecord-datastore-adapter"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency( 'appengine-apis', '0.0.22' )
  s.add_dependency( 'activerecord', '>= 3.0.3' )
  s.add_dependency( 'arel', '>= 2.0.7' )
end
