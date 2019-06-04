require 'dotenv/tasks'
require 'securerandom'

namespace :db do
  task :reset_schema_cmds, [:app, :env] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: reset_schema")

    database = "uss_#{args.app}_#{args.env}"
    user = "uss_#{args.app}_#{args.env}"

    Rails.logger.info("-----------------------")

    puts "DROP SCHEMA IF EXISTS uss CASCADE;"
    puts "CREATE SCHEMA uss;"
    puts "GRANT ALL PRIVILEGES ON SCHEMA uss TO #{user};"
    puts "ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO #{user};"
    puts "GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user};"
    puts ""
    puts "GRANT USAGE ON SCHEMA uss to #{user}_reader;"
    puts "GRANT SELECT ON ALL TABLES IN SCHEMA uss TO #{user}_reader;"
    puts "GRANT SELECT ON ALL SEQUENCES IN SCHEMA uss TO #{user}_reader;"
    puts "ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT ON TABLES TO #{user}_reader;"
    puts "ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT ON SEQUENCES TO #{user}_reader;"

    Rails.logger.info("-----------------------")
  end


  task :create_environments, [:admin, :app] => [:environment, :dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:create_environments")

    admin = args.admin
    app = args.app

    create_environments(admin, app)
  end

  task :destroy_environments, [:admin, :app] => [:environment, :dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:destroy_environments")

    admin = args.admin
    app = args.app

    destroy_environments(admin, app)
  end


  task :create_database, [:admin, :app, :env] => [:environment, :dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:create_database start task")

    admin = "#{args.admin}"
    user = "uss_#{args.app}_#{args.env}"
    database = "uss_#{args.app}_#{args.env}"

    create_database(admin, user, database)
  end

  task :create_schema, [:admin, :app, :env] => [:environment, :dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:create_schema start task")

    admin = "#{args.admin}"
    user = "uss_#{args.app}_#{args.env}"
    database = "uss_#{args.app}_#{args.env}"

    create_database(admin, user, database)
    create_schema(admin, user, database)

    #Rake['db:migrate'].invoke

  end


  task :sync_prod_to_local, [:admin, :app, :env] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: sync_prod_to_local")

    app = args.app
    database = "uss_#{args.app}_#{args.env}"
    user = "uss_#{args.app}_#{args.env}"
    admin = args.admin
    backup_file = "~/tmp/#{database}_backup.db"

    # Get production data locally
    Rails.logger.debug("Backup Production Database")

    `pg_dump --no-owner --no-acl -Z0 --schema=uss -haurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`

    # Clear out local postgres database
    reset_schema(admin, user, database, backup_file)
  end


  task :reset_schema, [:admin, :app, :env] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: reset_schema: admin: #{args.admin}, app: #{args.app}, env: #{args.env}")

    admin = args.admin
    user = "uss_#{args.app}_#{args.env}"
    Rails.logger.info("DB:: reset_schema: user: #{user}")
    database = "uss_#{args.app}_#{args.env}"
    backup_file = "~/tmp/#{database}_backup.db"

    reset_schema(admin, user, database, backup_file)
  end
  #
  # task :sync_db_test, [:app,:env] do |t, args|
  #   Rails.logger = Logger.new(STDOUT)
  #   Rails.logger.info("DB:: sync_db_local")
  #
  #   app = args.app
  #   database = "uss_#{args.app}_#{args.env}"
  #   user = "uss_#{args.app}_#{args.env}"
  #   backup_file = "~/tmp/#{database}_backup.db"
  #
  #   # Get production data locally
  #   Rails.logger.debug("Backup Production Database")
  #
  #   `pg_dump --no-owner --no-acl -Z0 --schema=uss -haurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`
  #
  #   # Clear out local postgres database
  #   reset_test(user, database, backup_file)
  # end
  #
  # task :sync_db_local, [:admin,:app,:env] do |t, args|
  #   Rails.logger = Logger.new(STDOUT)
  #   Rails.logger.info("DB:: sync_db_local")
  #
  #   app = args.app
  #   database = "uss_#{args.app}_#{args.env}"
  #   user = "uss_#{args.app}_#{args.env}"
  #   admin=args.admin
  #   backup_file = "~/tmp/#{database}_backup.db"
  #
  #   # Get production data locally
  #   Rails.logger.debug("Backup Production Database")
  #
  #   `pg_dump --no-owner --no-acl -Z0 --schema=uss -haurora-postgres-1.ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`
  #
  #   # Clear out local postgres database
  #   reset_local(admin, user, database, backup_file)
  # end
  #
  # task :reset_local, [:admin, :app, :env] do |t, args|
  #   Rails.logger = Logger.new(STDOUT)
  #   Rails.logger.info("DB:: postgres_migrate")
  #
  #   database = "uss_#{args.app}_#{args.env}"
  #   user = "uss_#{args.app}_#{args.env}"
  #   admin = args.admin
  #   backup_file = "~/tmp/#{database}_backup.db"
  #
  #
  #   reset_local(admin, user, database, backup_file)
  #
  # end
  #
  # private
  #

  def create_environments(admin, app)
    Rails.logger.info("db:create_environments")

    dev = OpenStruct.new ({shell_name: "Novel", database: "", user: "", pwd: "", })
    test = OpenStruct.new ({shell_name: "Grass", database: "", user: "", pwd: "", })
    stage = OpenStruct.new ({shell_name: "Ocean", database: "", user: "", pwd: "", })
    prod = OpenStruct.new ({shell_name: "Red Sands", database: "", user: "", pwd: "", })
    environments = {dev: dev, test: test, stage: stage, prod: prod}

    # setup envionment conventions
    environments.each do |key, e|
      e.pwd = SecureRandom.hex(12)
      e.database = "uss_#{app}_#{key}"
      e.user = "uss_#{app}_#{key}"
    end

    #create users
    environments.each do |key, e|
      `psql -U #{admin}  -d postgres -tc "SELECT 1 FROM pg_user WHERE usename = '#{e.user}'" | grep -q 1 || psql -U #{admin}  -d postgres -c "CREATE USER #{e.user} WITH ENCRYPTED PASSWORD '#{e.pwd}'"`
    end


    shell_envs = {"dev": "Novel", "test": "Grass", "stage": "Ocean", "prod": "Red Sands"}

    # update .pgpqass with new passwords, if missing
    `grep -q  "##{app}" ~/.pgpass`; result = $?.success?
    if !result
      `echo "##{app}" >> ~/.pgpass`

      environments.each do |key, e|
        host = "localhost"
        `grep -q  "#{host}:5432:#{e.user}:#{e.database}:" ~/.pgpass`; result = $?.success?
        if !result

          `echo "#{host}:5432:#{e.user}:#{e.database}}:#{e.pwd}" >> ~/.pgpass`

          # if environment == "dev"
          #   `sed -E "s/localhost:5432:#{user}:#{database}:.*/localhost:5432:#{user}:#{database}:#{pwd}/" ~/.pgpass > ~/.pgpass.new`
          #   `cp ~/.pgpass.new ~/.pgpass`
          # end
          #
        end
      end

      environments.each do |key, e|
        host = "aurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com"
        `grep -q  "#{host}:5432:#{e.user}:#{e.database}:" ~/.pgpass`; result = $?.success?
        if !result
          `echo "#{host}:5432:#{e.user}:#{e.database}:UpdateWithAWSPassword" >> ~/.pgpass`
        end
      end
    end

    #
    # # update .pgpqass with new passwords, if missing
    # `grep -q  "localhost:5432:#{user}:#{database}:" ~/.pgpass` ; result=$?.success?
    # if !result
    #   `echo "##{app}" >> ~/.pgpass`
    #
    #   ["dev","test","stage","prod"].each do |environment|
    #     `echo "localhost:5432:uss_#{app}_#{environment}:uss_#{app}_#{environment}:#{pwd}" >> ~/.pgpass`
    #
    #     if environment == "dev"
    #       `sed -E "s/localhost:5432:#{user}:#{database}:.*/localhost:5432:#{user}:#{database}:#{pwd}/" ~/.pgpass > ~/.pgpass.new`
    #     end
    #   end
    #   host = "aurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com"
    #   ["test","stage","prod"].each do |environment|
    #     `echo "#{host}:5432:uss_#{app}_#{environment}:uss_#{app}_#{environment}:#{pwd}" >> ~/.pgpass`
    #   end
    # end
    #
    #
    # #sed -E 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' /tmp/ufos_prod.db > /tmp/ufos_prod.tmp.db
    #
    # `cp ~/.pgpass.new ~/.pgpass`


    # update database.yml file, set dev password
    # database = YAML.load(ERB.new(IO.read(File.join(Rails.root, "config", "database.yml"))).result)
    # puts "#{database["development"]["password"]}"
    # database["development"]["password"] = pwd
    # File.open(File.join(Rails.root, "config", "../../#{app}/database.yml"), 'w') { |f| YAML.dump(database, f) }


    # update .database_profile
    #
    `grep -q  "##{app}" ~/.database_profile`; result = $?.success?
    if !result
      alias_section = ["##{app}"]
      host = "localhost"
      environments.each do |key, e|
        if key == "dev".to_sym
          alias_section << "alias #{app}.db='psql -h #{host} -U #{e.user} #{e.database}'"
        else
          alias_section << "alias #{app}.db.#{key}.local='psql -h #{host} -U #{e.user} #{e.database}'"
        end
      end
      host = "aurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com"
      environments.each do |key, e|
        if key != "dev"
          alias_section << "alias #{app}.db.#{key}=\\\"term.sh \\'psql -h #{host} -U #{e.user} #{e.database}\\' \\'#{e.shell_name}\\'\\\""
        end
      end

      `echo "#{alias_section.join("\n")}" >> ~/.database_profile`
    end

    # shell_envs ={"dev": "Novel", "test": "Grass", "stage": "Ocean", "prod": "Red Sands" }
    #
    # host = "aurora-postgres-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com"
    # `grep -q  "##{app}" ~/.database_profile` ; result=$?.success?
    # if !result
    #   alias_section = ["##{app}"]
    #   ["dev","test","stage","prod"].each do |environment|
    #     if environment == "dev"
    #       alias_section << "alias #{app}.db='psql -h localhost -U uss_#{app}_#{environment} uss_#{app}_#{environment}'"
    #     else
    #       alias_section << "alias #{app}.db.#{environment}=\\\"term.sh \\'psql -h #{host} -U #{e.user} #{e.database}\\' \\'#{e.shell_name}\\'\\\""
    #     end
    #   end
    #
    #   ["test","stage","prod"].each do |environment|
    #     shell_env = shell_envs[environment.to_sym]
    #     alias_section << "alias #{app}.db.#{environment}=\\\"term.sh \\'psql -h aurora-postgres-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com -U  uss_#{app}_#{environment} uss_#{app}_#{environment}\\' \\'#{shell_env}\\'\\\""
    #   end
    #
    #   if alias_section.length > 1
    #     `echo "#{alias_section.join("\n")}" >> ~/.database_profile`
    #   end
    # end

  end


  def update_pgpass(admin, user, app, env)

  end

  def create_database(admin, user, database)
    Rails.logger.info("DB:: Create Database")

    `psql -U #{admin}  -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '#{database}'" | grep -q 1 || psql -U #{admin} -d postgres -c "CREATE DATABASE #{database}"`
    `psql -h localhost -U#{admin} -d #{database} -c 'GRANT ALL PRIVILEGES ON DATABASE #{database} TO #{user}'`
  end

  def create_schema(admin, user, database)
    Rails.logger.info("DB:: Create Schema")
    `psql -h localhost -U#{user} -d #{database} -c 'CREATE SCHEMA uss'`
    Rails.logger.info("DB:: Add Grants")
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT ALL PRIVILEGES ON SCHEMA uss TO #{user}, uss_admin'`
    `psql -h localhost -U#{user} -d #{database} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO #{user}'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user}'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user}'`
    Rails.logger.info("DB:: Set search path")
    `psql -h localhost -U #{admin} -d postgres -c 'ALTER DATABASE #{database} SET SEARCH_PATH TO uss, public'`
  end

  def destroy_environments(admin, app)

    Rails.logger.info("db:destroy_environments")
    dev = OpenStruct.new ({shell_name: "Novel", database: "", user: ""})
    test = OpenStruct.new ({shell_name: "Grass", database: "", user: ""})
    stage = OpenStruct.new ({shell_name: "Ocean", database: "", user: ""})
    prod = OpenStruct.new ({shell_name: "Red Sands", database: "", user: ""})
    environments = {dev: dev, test: test, stage: stage, prod: prod}

    # setup envionment conventions
    environments.each do |key, e|
      e.database = "uss_#{app}_#{key}"
      e.user = "uss_#{app}_#{key}"
    end

    #drop
    environments.each do |key, e|

      # Drop schema
      #`psql -U #{admin}  -d postgres -c "DROP SCHEMA uss IF EXISTS"`

      # Drop database
      `psql -U #{admin}  -d postgres -c "DROP DATABASE IF EXISTS #{e.database} "`

      # Drop user
      `psql -U #{admin}  -d postgres -tc "SELECT 1 FROM pg_user WHERE usename = '#{e.user}'" | grep -q 1 || psql -U #{admin}  -d postgres -c "DROP USER #{e.user} "`

    end

  end

  def reset_schema(admin, user, database, backup_file)
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: reset_schema: admin: #{admin}, user: #{user}, database: #{database}")

    Rails.logger.info("DB:: Drop Schema")
    `psql -h localhost -U#{user} -d #{database} -c 'DROP SCHEMA IF EXISTS uss CASCADE'`

    create_schema(admin, user, database)

    Rails.logger.info("DB:: Import: #{backup_file}")
    `psql -h localhost -U #{user} #{database} < #{backup_file}`

  end
  #
  # def reset_test(user, database, backup_file)
  #   Rails.logger = Logger.new(STDOUT)
  #   Rails.logger.info("DB:: reset_test")
  #
  #   host = "aurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com"
  #
  #   Rails.logger.info("DB:: Drop Schema")
  #   `psql -h #{host} -U#{user} -d #{database} -c 'DROP SCHEMA IF EXISTS uss CASCADE'`
  #   Rails.logger.info("DB:: Create Schema")
  #   `psql -h #{host} -U#{user} -d #{database} -c 'CREATE SCHEMA uss'`
  #   Rails.logger.info("DB:: Add Grants")
  #   `psql -h #{host} -U#{user} -d #{database} -c 'GRANT ALL PRIVILEGES ON SCHEMA uss TO #{user}'`
  #   `psql -h #{host} -U#{user} -d #{database} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO #{user}'`
  #   `psql -h #{host} -U#{user} -d #{database} -c 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user}'`
  #   `psql -h #{host} -U#{user} -d #{database} -c 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user}'`
  #   Rails.logger.info("DB:: Set search path")
  #   #`psql -h #{host} -U #{admin} -d postgres -c 'ALTER DATABASE #{database} SET SEARCH_PATH TO uss, public'`
  #
  #   Rails.logger.info("DB:: Import: #{backup_file}")
  #   `psql -h #{host} -U #{user} #{database} < #{backup_file}`
  #
  # end

end