# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dstore/version"

Gem::Specification.new do |s|
  s.name        = "dstore"
  s.version     = Dstore::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["TODO: Write your name"]
  s.email       = ["TODO: Write your email address"]
  s.homepage    = "http://rubygems.org/gems/dstore"
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "dstore"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency( 'activerecord', '>= 3.0.3' )
  s.add_dependency( 'appengine-apis', '>= 0.0.22' )
end
