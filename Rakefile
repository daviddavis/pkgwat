require 'bundler/gem_tasks'
require 'pkgwat/tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "test"
  t.verbose = true
  t.pattern = 'test/**/*_test.rb'
end

task :default => [:test]
