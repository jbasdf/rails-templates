def file_append(file, data)
  log 'file_append', file
  append_file(file, data)
end

def file_inject(file_name, sentinel, string, before_after=:after)
  log 'file_inject', file_name
  gsub_file file_name, /(#{Regexp.escape(sentinel)})/mi do |match|
    if :after == before_after
      "#{match}\n#{string}"
    else
      "#{string}\n#{match}"
    end
  end
end


install_muck_activity = true if yes?('Install activity system? (y/n)')
install_file_uploads = true if yes?('Install file uploads? (y/n)')
install_cms_lite = true if yes?('Install CMS Lite? (y/n)')
install_solr = true if yes?('Install Acts As Solr? (y/n)')
install_disguise = true if yes?('Install disguise theme engine? (y/n)')
setup_submodules_for_development = true if yes?('Setup submodules for development?')

#====================
# gems 
#====================
gem 'cms-lite', :lib => 'cms_lite' if install_cms_lite
gem 'uploader' if install_file_uploads
gem 'disguise' if install_disguise

#====================
# plugins 
#====================


#====================
# stuff we tweaked
#====================
if install_solr
  plugin 'acts_as_solr', :git => "git://github.com/oxtralite/acts_as_solr.git", :submodule => true
end

#====================
# muck activity engine
#====================
if install_muck_activity
  plugin 'muck_activity_engine', :git => "git://github.com/jbasdf/muck_activity_engine.git", :submodule => true
  rake('muck:activity:sync')
end

#====================
# cms lite
#====================
if install_cms_lite
  file_append 'Rakefile', <<-CODE
    require 'cms_lite'
    require 'cms_lite/tasks'
  CODE
end

#====================
# disguise
#====================
if install_disguise
  file_append 'Rakefile', <<-CODE
    require 'disguise/tasks'
  CODE
  rake('disguise:setup')
  rake('db:migrate')
end


#====================
# uploader
#====================
if install_file_uploads
  
  file_append 'Rakefile', <<-CODE
    require 'uploader'
    require 'uploader/tasks'
  CODE
  
  initializer 's3_credentials.rb', <<-CODE
  # This keeps the developers from having to have the Amazon keys on their machines
  s3_file = "\#{RAILS_ROOT}/config/s3.yml"
  if File.exist?(s3_file)
    AMAZON_S3_CREDENTIALS = s3_file
  else
    AMAZON_S3_CREDENTIALS = { 
      :access_key_id => '',
      :secret_access_key => ''
    }
  end
  CODE
  
  
  file 'app/models/uploads.rb', <<-CODE
  class Upload < ActiveRecord::Base
  
    acts_as_uploader  :enable_s3 => false,
                      :has_attached_file => {
                        :url     => "/system/:attachment/:id_partition/:style/:basename.:extension",
                        :path    => ":rails_root/public/system/:attachment/:id_partition/:style/:basename.:extension",
                        :styles  => { :icon => "30x30!", 
                                      :thumb => "100>", 
                                      :small => "150>", 
                                      :medium => "300>", 
                                      :large => "660>"},
                        :default_url => "/images/profile_default.jpg",
                        :storage => :s3,
                        :s3_credentials => AMAZON_S3_CREDENTIALS,
                        :bucket => "assets.\#{SITE[:domain]}",
                        :s3_host_alias => "assets.\#{SITE[:domain]}",
                        :convert_options => {
                           :all => '-quality 80'
                         }
  
  end
  CODE
  
  rake('uploader:sync')
end



# Initialize submodules
git :submodule => "init"

if setup_submodules_for_development
  if install_muck_activity
    inside ('vendor/plugins/muck_activity_engine') do
      run "git remote add my git@github.com:jbasdf/muck_activity_engine.git"
    end
  end
  if install_solr
    inside ('vendor/plugins/acts_as_solr') do
      run "git remote add my git@github.com:oxtralite/acts_as_solr.git"
    end
  end
end