require 'dotenv/tasks'
require 'securerandom'

namespace :db do
  task :create_user, [:app, :env] do |t, args|
    e.pwd = SecureRandom.hex(12)

    e.database = "uss_#{app}_#{key}"
    e.user = "uss_#{app}_#{key}"

    puts "CREATE USER #{e.user} WITH ENCRYPTED PASSWORD '#{e.pwd}'"
  end
end