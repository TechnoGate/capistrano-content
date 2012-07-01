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

    desc '[internal] backup content folders'
    task :backup, :roles => :app do
      set :latest_content_backup,
        "#{fetch :backup_path, "#{fetch :deploy_to}/backups"}/#{fetch :application}_shared_contents_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.tar.gz"
      on_rollback { run "rm -f #{fetch :latest_content_backup}" }

      run <<-CMD
        cd #{fetch :shared_content_path} &&
        tar chzf #{fetch :latest_content_backup} --exclude='*~' --exclude='*.tmp' --exclude='*.bak' *
      CMD
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

    desc 'Import content'
    task :import, :roles => :app do
      transaction do
        tmp_file = random_tmp_file
        on_rollback { run "rm -f #{tmp_file}" }
        backup
        write File.read(arguments), tmp_file
        run <<-CMD
          cd #{fetch :shared_content_path} &&
          tar xf #{tmp_file} &&
          rm -f #{tmp_file}
        CMD
      end
    end

    desc '[internal] Cleanup the content folder'
    task :clean, :roles => :app do
      find_params = ["-name '._*'", "-name '*~'", "-name '*.tmp'", "-name '*.bak'"]
      commands = find_params.inject '' do |commands, find_param|
        commands << "#{try_sudo} find #{fetch :shared_content_path} #{find_param} -exec rm -f {} ';';"
      end

      run commands
    end
  end

  after 'deploy:setup', 'content:setup'
  after 'deploy:finalize_update', 'content:link'
end