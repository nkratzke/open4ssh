require "bundler/gem_tasks"
require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'README.md', 'LICENSE.txt', 'CHANGELOG.md']
  t.stats_options = ['--list-undoc']
end