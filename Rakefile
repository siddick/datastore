require 'bundler'
Bundler::GemHelper.install_tasks

desc "Test examples"
task :test do
  raise "Need jruby" if RUBY_ENGINE != "jruby"
  system 'rspec spec/*_spec.rb'
end

