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

install_muck_content = true if yes?('Install content system? (y/n)')
install_muck_activity = true if yes?('Install activity system? (y/n)')
install_muck_profiles = true if yes?('Install profile system? (y/n)') || install_muck_activity
install_muck_friends = true if yes?('Install friends system? (y/n)')
install_file_uploads = true if yes?('Install file uploads? (y/n)')
install_cms_lite = true if yes?('Install CMS Lite? (y/n)')
install_solr = true if yes?('Install Acts As Solr? (y/n)') || install_muck_content
install_disguise = true if yes?('Install disguise theme engine? (y/n)')
install_muck_comments = true if yes?('Install muck comment engine?  This is required for the muck activity engine. (y/n)') || install_muck_activity
install_tagging = true if yes?('Install Tagging? (y/n)') || install_muck_content

#====================
# muck solr
#====================
if install_solr
  gem 'muck-solr', :lib => 'acts_as_solr'
end

#====================
# muck content engine
#====================
if install_muck_content
  gem 'muck-contents', :lib => 'muck_contents'
  
  file_append 'Rakefile', <<-CODE
    require 'muck_contents/tasks'
  CODE
  rake('rake muck:contents:sync')
  
  file 'app/models/content.rb', <<-CODE
    class Content < ActiveRecord::Base
      acts_as_muck_content(
        :git_repository => GlobalConfig.content_git_repository,
        :enable_auto_translations => GlobalConfig.enable_auto_translations,
        :enable_solr => GlobalConfig.content_enable_solr
      )
  
      # Add search to your content.  Be sure to install muck-solr or another acts_as_solr.  This is left
      # for the model so that you can choose what kind of search to implement
      acts_as_solr :fields => [ :search_content ]
      def search_content
        "\#{title} \#{body} \#{tags.collect{|t| t.name}.join(' ')}"
      end
    
    end
  CODE
  
  file 'app/models/content_translation.rb', <<-CODE
  class ContentTranslation < ActiveRecord::Base
    acts_as_muck_content_translation
  end
  CODE
  
  file 'app/models/content_permission.rb', <<-CODE
  class ContentPermission < ActiveRecord::Base
    acts_as_muck_content_permission
  end
  CODE
  
end

#====================
# muck profile engine
#====================
if install_muck_profiles
  gem 'muck-profiles', :lib => 'muck_profiles'
  
  file_append 'Rakefile', <<-CODE
    require 'muck_profiles/tasks'
  CODE
  rake('rake muck:profiles:sync')
  
  file 'app/models/profile.rb', <<-CODE
  class Profile < ActiveRecord::Base
    acts_as_muck_profile
  end
  CODE
  
end

#====================
# muck activity engine
#====================
if install_muck_activity
  gem 'muck-activities', :lib => 'muck_activities'
  file_append 'Rakefile', <<-CODE
    require 'muck_activities/tasks'
  CODE
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  # activity configuration
  enable_live_activity_updates: true              # Turns on polling inside the user's activity feed so they constantly get updates from the site
  live_activity_update_interval: 60               # Time between updates to live activity feed in seconds.  Setting this number to low can put quite a bit of strain on your site.
  enable_activity_comments: true                  # Turn on comments inside the activity feed
  CODE
  
  rake('muck:activities:sync')
end

#====================
# muck friends engine
#====================
if install_muck_friends
  gem 'muck-friends', :lib => 'muck_friends'
  file_append 'Rakefile', <<-CODE
    require 'muck_friends/tasks'
  CODE
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  # Friend configuration
  allow_following:  true                          # If true then users can 'follow' each other.  If false then only friend requests will be used.
  enable_friend_activity: true                    # If true then friend related activity will show up in the activity feed.  Requires muck-activities gem
  CODE

  rake('muck:friends:sync')
end

#====================
# cms lite
#====================
if install_cms_lite
  gem 'cms-lite', :lib => 'cms_lite'
  file_append 'Rakefile', <<-CODE
    require 'cms_lite'
    require 'cms_lite/tasks'
  CODE
end

#====================
# disguise
#====================
if install_disguise
  gem 'disguise'
  file_append 'Rakefile', <<-CODE
    require 'disguise/tasks'
  CODE
  rake('disguise:setup')
  rake('db:migrate')
  
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  #theme configuration
  use_domain_for_themes: false                    # Setting for the disguise plugin.  Themes can be set in the admin UI or determined at run time by the domain name.
  CODE
  
end


#====================
# uploader
#====================
if install_file_uploads
  gem 'uploader'
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
  
  
  file 'app/models/upload.rb', <<-CODE
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


#====================
# muck comments
#====================
if install_muck_comments

  # nested set is required for comments
  gem "collectiveidea-awesome_nested_set", :lib => 'awesome_nested_set'
  
  file 'app/models/comment.rb', <<-CODE
  class Comment < ActiveRecord::Base
    
    acts_as_muck_comment
    
    # TODO polish the add to activity for comment
    def after_create
      # if !self.commentable.is_a?(Activity) # don't add comments to the activity feed that are comments on the items in the activity feed.
      content = I18n.t('muck.comments.new_comment')
      add_activity(self, self, self, 'comment', '', content)
    end
  
    def self.between_users user1, user2
      find(:all, {
        :order => 'created_at asc',
        :conditions => [
          "(user_id=? and commentable_id=?) or (user_id=? and commentable_id=?) and commentable_type='User'",
          user1.id, user2.id, user2.id, user1.id]
          })
    end

  end
  CODE

  file 'app/controllers/comment_controller.rb', <<-CODE
  class CommentsController < Muck::CommentsController
    
    before_filter :login_required # require the user to be logged in to make a comment
    
    # Modify this method to change how permissions are checked to see if a user can comment.
    # Each model that implements 'acts_as_muck_comment' can override can_comment? to 
    # change how comment permissions are handled.
    def has_permission_to_comment(user, parent)
      parent.can_comment?(user)
    end
    
  end
  CODE
  
  file_append 'Rakefile', <<-CODE
    require 'muck_comments/tasks'
  CODE

  file_inject 'config/routes.rb', "map.root :controller => 'default', :action => 'index'", <<-CODE
  map.resources :comments
  CODE
  
end


#====================
# tagging
#====================
if install_tagging
  gem 'mbleigh-acts-as-taggable-on', :source => "http://gems.github.com", :lib => "acts-as-taggable-on"
  file_inject('app/helpers/application_helper.rb', 'module ApplicationHelper', 'include TagsHelper')
  file_inject('app/models/user.rb', 'class User < ActiveRecord::Base', 'acts_as_tagger')
  run "script/generate acts_as_taggable_on_migration"
end
