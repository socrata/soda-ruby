require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

require 'rubocop/rake_task'

desc 'Run RuboCop on the lib directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb']
  # don't abort rake on failure
  task.fail_on_error = false
end

desc 'Run tests'
task :default => :test
