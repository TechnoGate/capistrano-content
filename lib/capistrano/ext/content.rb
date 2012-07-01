Capistrano::Configuration.instance(:must_exist).load do
  set :shared_content_path, -> { "#{fetch :shared_path}/shared_contents" }

  namespace :content do
    desc 'setup the content folders'
    task :setup, :roles => :app do
      commands = "#{try_sudo} mkdir -p #{fetch :shared_content_path};"
      fetch(:content_folders, []).each do |folder, path|
        commands << "#{try_sudo} mkdir -p #{fetch :shared_content_path}/#{folder};"
      end

      run commands
    end

    desc 'Import content'
    task :import, :roles => :app do
      tmp_file = random_tmp_file
      on_rollback { run "rm -f #{tmp_file}" }

      transaction do
        backup
        write File.read(arguments.first), tmp_file
        run <<-CMD
          cd #{fetch :shared_content_path} &&
          tar xf #{tmp_file} &&
          rm -f #{tmp_file}
        CMD
        clean
      end
    end

    desc 'Export content'
    task :export, :roles => :app do
      tmp_file = "#{arguments(false).first || random_tmp_file}"
      tmp_file << '.tar.gz' unless tmp_file =~ /\.tar\.gz$/
      on_rollback { run "rm -f #{fetch :latest_content_backup}" }
      on_rollback { run_locally "rm -f #{tmp_file}" }

      transaction do
        backup
        download fetch(:latest_content_backup), tmp_file
        logger.important "The content folder has been downloaded to #{tmp_file}"
      end
    end


    desc '[internal] backup content folders'
    task :backup, :roles => :app do
      set :latest_content_backup,
        "#{fetch :backup_path, "#{fetch :deploy_to}/backups"}/#{fetch :application}_shared_contents_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.tar.gz"
      on_rollback { run "rm -f #{fetch :latest_content_backup}" }

      transaction do
        clean

        run <<-CMD
          cd #{fetch :shared_content_path} &&
          tar chzf #{fetch :latest_content_backup} *
        CMD
      end
    end

    desc '[internal] Link content folders'
    task :link, :roles => :app do
      commands = ""

      fetch(:content_folders, []).each do |folder, path|
        # At this point, the current_path does not exists and by running an mkdir
        # later, we're actually breaking stuff.
        # So replace current_path with latest_release in the contents_path string
        path.gsub! %r{#{current_path}}, latest_release

        # Remove the path, making sure it does not exists
        commands << "#{try_sudo} rm -f #{path};"

        # Make sure we have the folder that'll contain the shared path
        commands << "#{try_sudo} mkdir -p #{File.dirname(path)};"

        # Create the symlink
        commands << "#{try_sudo} ln -nsf #{shared_path}/shared_contents/#{folder} #{path};"
      end

      run commands
    end

    desc '[internal] Cleanup the content folder'
    task :clean, :roles => :app do
      clean_folder fetch(:shared_content_path)
    end
  end

  after 'deploy:setup', 'content:setup'
  after 'deploy:finalize_update', 'content:link'
end
