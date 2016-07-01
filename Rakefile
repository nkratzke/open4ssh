require "bundler/gem_tasks"
require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'README.md', 'LICENSE.txt']
  # t.options = ['--any', '--extra', '--opts']
  t.stats_options = ['--list-undoc']
end