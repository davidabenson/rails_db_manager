require 'dotenv/tasks'
require 'securerandom'

namespace :docker do
  task :build, [:app, :env] do |t, args|
    e.pwd = SecureRandom.hex(12)

    app = args.app
    env = args.app
    app_name = "uss_#{app}_#{env}"

    puts "Docker build:  #{app_name}"

    `git log -1 --pretty=%h`; result = $?.success?

    puts "git sha: #{result}"
    # if !result
    #   `docker build --build-arg master_key=1fe775c7f2eac3b7b7069bc21be317d9 --build-arg rails_env=#{env} -t #{app_name}:latest . ; say -v Karen "Dave, The build is done"`
    # end
  end
end