require 'dotenv/tasks'
require 'securerandom'

namespace :db do
  task :reset_schema_cmds, [:app, :env] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: reset_schema")

    database = "uss_#{args.app}_#{args.env}"
    user = "uss_#{args.app}_#{args.env}"

    puts "-----------------------"

    puts "CREATE EXTENTION hstore;"

    puts("DB:: Drop Schema")
    puts("DROP SCHEMA IF EXISTS uss CASCADE;")
    puts("CREATE SCHEMA uss;")
    puts ""
    puts "GRANT CONNECT ON DATABASE #{database} TO #{user};"
    puts "GRANT CONNECT ON DATABASE #{database} TO #{user}_reader;"
    puts ""
    puts "-- **** Reset after database is created ****"
    puts "ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO #{user};"
    puts "GRANT SELECT,INSERT,UPDATE,DELETE,TRIGGER ON ALL TABLES IN SCHEMA uss TO #{user};"
    puts "GRANT TRIGGER ON All TABLES IN SCHEMA public to #{user};"
    puts "GRANT TRIGGER ON All TABLES IN SCHEMA uss to #{user};"
    puts ""
    puts "-- reader account reset"
    puts "GRANT USAGE ON SCHEMA uss to #{user}_reader;"
    puts "GRANT SELECT ON ALL TABLES IN SCHEMA uss TO #{user}_reader;"
    puts "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO #{user}_reader;"
    puts "GRANT SELECT ON ALL SEQUENCES IN SCHEMA uss TO #{user}_reader;"
    puts "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO #{user}_reader;"
    puts "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO #{user}_reader;"
    puts "DB:: Set search path"
    puts "ALTER DATABASE #{database} SET SEARCH_PATH TO uss, public"

    puts "-----------------------"
  end


  task :create_environments, [:admin, :app] => [:dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:create_environments")

    admin = args.admin
    app = args.app

    create_environments(admin, app)
  end

  task :destroy_environments, [:admin, :app] => [:dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:destroy_environments")

    admin = args.admin
    app = args.app

    destroy_environments(admin, app)
  end


  task :create_database, [:admin, :app, :env] => [:dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:create_database start task")

    admin = "#{args.admin}"
    user = "uss_#{args.app}_#{args.env}"
    database = "uss_#{args.app}_#{args.env}"

    create_database(admin, user, database)
  end

  task :create_schema, [:admin, :app, :env] => [:dotenv] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("db:create_schema start task")

    admin = "#{args.admin}"
    user = "uss_#{args.app}_#{args.env}"
    database = "uss_#{args.app}_#{args.env}"

    create_database(admin, user, database)
    create_schema(admin, user, database)

    #Rake['db:migrate'].invoke

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

  task :sync_prod_to_local, [:admin, :app, :env] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: sync_prod_to_local")

    app = args.app
    database = "uss_#{args.app}_#{args.env}"
    user = "uss_#{args.app}_#{args.env}"
    admin = args.admin
    backup_file = "~/tmp/#{database}_backup.db"


    dump_prod('aurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com', "uss_#{app}_prod", "uss_#{app}_prod", backup_file)
    # # Get production data locally
    # Rails.logger.debug("Backup Production Database")
    #
    # `pg_dump --no-owner --no-acl -Z7 -Fc --exclude-table-data session --exclude-table-data event_log --exclude-table-data version --exclude-table _old_version --schema=uss -haurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`

    # Clear out local postgres database
    reset_schema(admin, user, database, backup_file)
  end

  # task :sync_moderate_prod_to_environment, [:app, :env] do |t, args|
  #   Rails.logger = Logger.new(STDOUT)
  #   Rails.logger.info("DB:: sync_moderate_prod_to_environment")
  #
  #   app = args.app
  #   env = args.env
  #   database = "uss_#{app}_#{env}"
  #   user = "uss_#{app}_#{env}"
  #   backup_file = "~/tmp/#{database}_backup.db"
  #   aws_host = "aurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com"
  #
  #   dest_host = aws_host
  #   if env == "dev" || env == "prod"
  #     dest_host = "localhost"
  #   end
  #
  #   dump_prod(aws_host, "uss_#{app}_prod", "uss_#{app}_prod", backup_file)
  #
  #   # # Get production data locally
  #   # Rails.logger.debug("Backup Production Database")
  #   #
  #   # `pg_dump --no-owner --no-acl -Z7 -Fc --schema=uss -h#{aws_host} -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`
  #
  #   # Clear out local postgres database
  #   Rails.logger.info("DB:: sync_db_local: user: #{user}")
  #   Rails.logger.info("DB:: sync_db_local: database: #{database}")
  #   Rails.logger.info("DB:: sync_db_local: dest_host: #{dest_host}")
  #   Rails.logger.info("DB:: sync_db_local: backup_file: #{backup_file}")
  #
  #   reset_moderate_database(user, database, dest_host, backup_file)
  # end

  task :sync_moderate_env_to_env, [:app, :from_env, :to_env] do |t, args|
    desc "Copy database from moderate environment to new environment, E.G.  rake db:sync_moderate_env_to_env[{ehs,esif..},{prod,stage,test],{dev,stage,test}]"
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: sync_moderate_env_to_env")

    app = args.app
    to_env = args.to_env
    from_env = args.from_env
    database = "uss_#{app}_#{to_env}"
    user = "uss_#{app}_#{to_env}"
    backup_file = "~/tmp/#{database}_backup.db"
    aws_host = "aurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com"

    dest_host = aws_host
    if to_env == "dev" || to_env == "prod"
      dest_host = "localhost"
    end

    dump_prod(aws_host, "uss_#{app}_#{from_env}", "uss_#{app}_#{from_env}", backup_file)
    # # Get production data locally
    # Rails.logger.debug("Backup #{from_env} Database")
    #
    # `pg_dump --no-owner --no-acl -Z7 -Fc --schema=uss -h#{aws_host} -Uuss_#{app}_#{from_env} uss_#{app}_#{from_env} > #{backup_file}`

    # Clear out local postgres database
    reset_moderate_database(user, database, dest_host, backup_file)
  end

  task :sync_low_prod_to_environment, [:app, :env] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: sync_low_prod_to_environment")

    app = args.app
    env = args.env
    database = "uss_#{app}_#{env}"
    user = "uss_#{app}_#{env}"
    backup_file = "~/tmp/#{database}_backup.db"
    aws_host = "aurora-postgres-1.ccklrxkcenui.us-west-2.rds.amazonaws.com"

    dest_host = aws_host
    if env == "dev"
      dest_host = "localhost"
    end

    dump_prod(aws_host, "uss_#{app}_prod", "uss_#{app}_prod", backup_file)

    # # Get production data locally
    # Rails.logger.debug("Backup Production Database")
    #
    # `pg_dump --no-owner --no-acl -Z7 -Fc --schema=uss -h#{aws_host} -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`

    # Clear out local postgres database
    reset_moderate_database(user, database, dest_host, backup_file)
  end


  # task :sync_moderate_prod_to_environment, [:app, :env] do |t, args|
  #   Rails.logger = Logger.new(STDOUT)
  #   Rails.logger.info("DB:: sync_db_local")
  #
  #   app = args.app
  #   database = "uss_#{args.app}_#{args.env}"
  #   user = "uss_#{args.app}_#{args.env}"
  #   backup_file = "~/tmp/#{database}_test_backup.db"
  #
  #   # Get production data locally
  #   Rails.logger.debug("Backup Production Database")
  #
  #   `pg_dump --no-owner --no-acl -Z7 --schema=uss -haurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`
  #
  #   # Clear out local postgres database
  #   reset_moderate_database(user, database, backup_file)
  # end

  task :sync_prod_to_stage, [:app, :env] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: sync_prod_to_stage")

    app = args.app
    database = "uss_#{args.app}_#{args.env}"
    user = "uss_#{args.app}_#{args.env}"
    backup_file = "~/tmp/#{database}_test_backup.db"

    dump_prod(aws_host, "uss_#{app}_prod", "uss_#{app}_prod", backup_file)


    # # Get production data locally
    # Rails.logger.debug("Backup Production Database")
    #
    # `pg_dump --no-owner --no-acl -Z7 -Fc --schema=uss -haurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`

    # Clear out local postgres database
    reset_test(user, database, backup_file)
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
  #   `pg_dump --no-owner --no-acl -Z7 --schema=uss -haurora-postgres-moderate-cluster-1.cluster-ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`
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
  #   `pg_dump --no-owner --no-acl -Z7 --schema=uss -haurora-postgres-1.ccklrxkcenui.us-west-2.rds.amazonaws.com -Uuss_#{app}_prod uss_#{app}_prod > #{backup_file}`
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

    Rails.logger.info("db:check if hstore extention exists")

    result = `psql -tAc "select 1 from pg_extension where extname='hstore'" template1 `
    if !(result.first == "1")
      Rails.logger.info("db:create hstore extention")
    `psql -h localhost -U#{admin} template1 -c 'CREATE EXTENSION hstore'`
    end


    dev = OpenStruct.new ({shell_name: "Novel", database: "", user: "", pwd: "", })
    unit = OpenStruct.new ({shell_name: "Novel", database: "", user: "", pwd: "", })
    test = OpenStruct.new ({shell_name: "Grass", database: "", user: "", pwd: "", })
    stage = OpenStruct.new ({shell_name: "Ocean", database: "", user: "", pwd: "", })
    prod = OpenStruct.new ({shell_name: "Red Sands", database: "", user: "", pwd: "", })
    environments = {dev: dev, unit: unit, test: test, stage: stage, prod: prod}

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

    #create bi reader users
    environments.each do |key, e|
      `psql -U #{admin}  -d postgres -tc "SELECT 1 FROM pg_user WHERE usename = '#{e.user}_reader'" | grep -q 1 || psql -U #{admin}  -d postgres -c "CREATE USER #{e.user}_reader WITH ENCRYPTED PASSWORD '#{e.pwd}'"`
    end



    shell_envs = {"dev": "Novel", "test": "Grass", "stage": "Ocean", "prod": "Red Sands"}

    # update .pgpqass with new passwords, if missing
    `grep -q  "##{app}" ~/.pgpass`; result = $?.success?
    unless result
      `echo "##{app}" >> ~/.pgpass`

      environments.each do |key, e|
        host = "localhost"
        `grep -q  "#{host}:5432:#{e.user}:#{e.database}:" ~/.pgpass`; result = $?.success?
        if !result

          `echo "#{host}:5432:#{e.user}:#{e.database}:#{e.pwd}" >> ~/.pgpass`

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

      #local unit tests need superuser
      # ALTER USER uss_ehs_test WITH SUPERUSER;
    `psql -U #{admin} -d postgres -tc "ALTER USER #{test.user} WITH SUPERUSER`

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
          alias_section << "alias #{app}.db.#{key}=\\\"term.sh \'psql -h #{host} -U #{e.user} #{e.database}\' \'#{e.shell_name}\'\\\""
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


  def update_pgpass(admin, user, app, env) end

  def create_database(admin, user, database)
    Rails.logger.info("DB:: Create Database")

    `psql -U #{admin}  -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '#{database}'" | grep -q 1 || psql -U #{admin} -d postgres -c "CREATE DATABASE #{database}"`
    `psql -h localhost -U#{admin} -d #{database} -c 'GRANT ALL PRIVILEGES ON DATABASE #{database} TO #{user}'`
  end

  def create_schema(admin, user, database)

    Rails.logger.info("DB:: Drop Schema")
    `psql -h localhost -U#{user} -d #{database} -c 'DROP SCHEMA IF EXISTS uss CASCADE'`

    Rails.logger.info("DB:: Create Schema uss")
    `psql -h localhost -U#{user} -d #{database} -c 'CREATE SCHEMA uss'`

    Rails.logger.info("DB:: Add Grants")
    `psql -h localhost -U#{user} -d #{database} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO #{user}'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user}'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT TRIGGER ON All TABLES IN SCHEMA public to #{user}'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT TRIGGER ON All TABLES IN SCHEMA uss to #{user}'`

    Rails.logger.info("DB:: reader account reset")
    `psql -h localhost -U#{user} -d #{database} -c 'DROP SCHEMA IF EXISTS bi CASCADE'`
    Rails.logger.info("DB:: Create Schema uss bi")
    `psql -h localhost -U#{user} -d #{database} -c 'CREATE SCHEMA bi'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT USAGE ON SCHEMA bi to #{user}_reader'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA bi TO #{user}_reader'`
    `psql -h localhost -U#{user} -d #{database} -c 'GRANT SELECT ON ALL SEQUENCES IN SCHEMA bi TO #{user}_reader'`

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

  def dump_prod(host, user, database, backup_file)
    # Get production data locally
    Rails.logger.debug("Backup Production Database")

    `pg_dump --no-owner --no-acl -Z7 -Fc --exclude-table-data session --exclude-table-data event_log --exclude-table-data version --exclude-table _old_version  -h#{host} -U#{user} #{database} > #{backup_file}`

  end

  def reset_schema(admin, user, database, backup_file)
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: reset_schema: admin: #{admin}, user: #{user}, database: #{database}")

    create_schema(admin, user, database)

    restore_database("localhost", user, database, backup_file)

  end

  def reset_moderate_database(user, database, host, backup_file)
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info("DB:: reset_moderate_database")

    Rails.logger.info("DB:: Drop Schema")
    `psql -h #{host} -U#{user} -d #{database} -c 'DROP SCHEMA IF EXISTS uss CASCADE'`
    Rails.logger.info("DB:: Create Schema")
    `psql -h #{host} -U#{user} -d #{database} -c 'CREATE SCHEMA uss'`
    Rails.logger.info("DB:: Add Grants")
    `psql -h #{host} -U#{user} -d #{database} -c 'GRANT ALL PRIVILEGES ON SCHEMA uss TO #{user}'`
    `psql -h #{host} -U#{user} -d #{database} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO #{user}'`
    `psql -h #{host} -U#{user} -d #{database} -c 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user}'`
    `psql -h #{host} -U#{user} -d #{database} -c 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA uss TO #{user}'`

    #`psql -h #{host} -U#{user} -d #{database} -c 'GRANT USAGE ON SCHEMA uss to #{user}_reader'`
    #`psql -h #{host} -U#{user} -d #{database} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA uss TO #{user}_reader'`
    #`psql -h #{host} -U#{user} -d #{database} -c 'GRANT SELECT ON ALL SEQUENCES IN SCHEMA uss TO #{user}_reader'`
    #`psql -h #{host} -U#{user} -d #{database} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT ON TABLES TO #{user}_reader'`
    #`psql -h #{host} -U#{user} -d #{database} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA uss GRANT SELECT ON SEQUENCES TO #{user}_reader'`

    Rails.logger.info("DB:: Set search path")
    #`psql -h #{host} -U #{admin} -d postgres -c 'ALTER DATABASE #{database} SET SEARCH_PATH TO uss, public'`

    restore_database(host, user, database, backup_file)

  end

  def restore_database(host, user, database, backup_file)
    Rails.logger.info("DB:: Import: #{backup_file} , Ignore any 'Already exists messages'")

    `pg_restore -Fc --no-owner --no-privileges -h #{host} -U  #{user} -d #{database} #{backup_file}`

    #Rails.logger.info("DB:: Vacuum: #{backup_file} , Ignore any 'Vacuum permission errors'")
    #`vacuumdb -q -z -h #{host} -U #{user} #{database}`
  end

end