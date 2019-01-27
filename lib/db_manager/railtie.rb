class DbManager::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/db_manager_tasks.rake'
  end
end