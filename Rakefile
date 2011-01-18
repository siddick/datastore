require 'bundler'
Bundler::GemHelper.install_tasks

desc "Make testing Environment"
task :create_test_app do
  system 'cd examples; rails new gapp -m rails3.rb'
end

desc "Test examples"
task :test do
  system 'cd examples/gapp; appcfg.rb run ../create_table_spec.rb'
end

desc "Test with Appengine irb"
task :irb do
  system 'cd examples/gapp; appcfg.rb run ../check_irb.rb -I ../../lib'
end

