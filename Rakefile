require "bundler/gem_tasks"
require 'yard'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'test/**/*.rb', '-', 'README.md', 'LICENSE.txt', 'CHANGELOG.md']
  t.stats_options = ['--list-undoc']
end