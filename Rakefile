require 'bundler'
Bundler::GemHelper.install_tasks
# require 'spec/rake/spectask'
# desc "Run all examples"
# Spec::Rake::SpecTask.new('examples') do |t|
#   t.spec_files = FileList['examples/*_spec.rb']
# end


desc "Make testing Environment"
task :create_test_app do
  # mkdir -p examples/gapp; cd examples/gapp; appcfg.rb generate_app .; echo "gem 'appengine-apis' \n gem 'activerecord'" >> Gemfile; appcfg.rb generate_app .
  puts "TODO"
end

desc "Test examples"
task :test do
  system 'cd examples/gapp; appcfg.rb run ../create_table_spec.rb'
end

desc "Test with Appengine irb"
task :irb do
  system 'cd examples/gapp; appcfg.rb run ../check_irb.rb -I ../../lib'
end

