install_muck_activity = true if yes?('Install activity system? (y/n)')
install_file_uploads if yes?('Install file uploads? (y/n)')

setup_submodules_for_development = true if yes?('Setup submodules for development?')

plugin 'paperclip', :git => "git://github.com/thoughtbot/paperclip.git" if install_file_uploads

# muck engines
plugin 'muck_activity_engine', :git => "git://github.com/jbasdf/muck_activity_engine.git", :submodule => true
rake('muck:activity:sync')


# Initialize submodules
git :submodule => "init"

if setup_submodules_for_development
  if install_muck_activity
    inside ('vendor/plugins/muck_activity_engine') do
      run "git remote add my git@github.com:jbasdf/muck_activity_engine.git"
    end
  end
end