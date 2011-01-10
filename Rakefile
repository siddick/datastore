require 'bundler'
Bundler::GemHelper.install_tasks
# require 'spec/rake/spectask'
# desc "Run all examples"
# Spec::Rake::SpecTask.new('examples') do |t|
#   t.spec_files = FileList['examples/*_spec.rb']
# end

desc "Test With Appengine"
task :test do
  system 'cd examples/gapp; appcfg.rb run ../create_table_spec.rb'
end

task :irb do
  system 'cd examples/gapp; appcfg.rb run ../check_irb.rb -I ../../lib'
end
