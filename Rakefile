require 'bundler'
Bundler::GemHelper.install_tasks

# Migrate DB
task :migrate do
    DataMapper.auto_migrate!
end
