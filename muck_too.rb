require 'ruby-debug'

def file_append(file, data)
  log 'file_append', file
  append_file(file, data)
end

def file_inject(file_name, sentinel, string, before_after = :after)
  log 'file_inject', file_name
  gsub_file file_name, /(#{Regexp.escape(sentinel)})/mi do |match|
    if :after == before_after
      "#{match}\n#{string}"
    else
      "#{string}\n#{match}"
    end
  end
end

def file_insert(file_name, sentinel, string, before_after = :after)
  log 'file_insert', file_name
  gsub_file file_name, /(#{Regexp.escape(sentinel)})/mi do |match|
    if :after == before_after
      "#{match} #{string} "
    else
      " #{string} #{match}"
    end
  end
end

def file_replace(file_name, string, replace)
  gsub_file file_name, /(#{Regexp.escape(string)})/mi do |match|
    "#{replace}"
  end
end


install_everything = true if yes?('Install everything? (y/n)')
if !install_everything
  install_muck_blogs = true if yes?('Install blog system? (Muck Blogs) (y/n)')
  install_muck_content = true if yes?('Install content system (Muck Content)? (y/n)')
  install_muck_profiles = true if yes?('Install profile system (Muck Profiles)? (y/n)')
  install_muck_raker = true if yes?('Muck Raker? (y/n)')
  install_muck_shares = true if yes?('Install muck shares (Muck Shares)? (y/n)')
  install_muck_activity = true if yes?('Install activity system (Muck Activities)? (y/n)')
  install_muck_friends = true if yes?('Install friends system (Muck Friends)? (y/n)')
  install_muck_invites = true if yes?('Install invite system (Muck Invites)? (y/n)')
  install_file_uploads = true if yes?('Install file uploads? (y/n)')
  install_cms_lite = true if yes?('Install CMS Lite? (y/n)')
  install_solr = true if yes?('Install Acts As Solr (Muck Solr)? (y/n)')
  install_disguise = true if yes?('Install disguise theme engine? (y/n)')
  install_muck_comments = true if yes?('Install comment engine (Muck Comments)?  This is required for the muck activity engine. (y/n)')
  install_tagging = true if yes?('Install Tagging? (y/n)')
  install_babelphish = true if yes?('Install Translations (babelphish - recommended)? (y/n)')
  install_geokit = true if yes?('Install Geokit? (y/n)')
  install_sms = true if yes?('Install SMS support? (y/n)')
  install_muck_oauth = true if yes?('Install Muck Oauth? (y/n)')
  
  # Deal with dependencies
  install_muck_shares ||= install_muck_raker
  install_muck_activity ||= install_muck_shares
  install_muck_content ||= install_muck_blogs
  install_muck_profiles ||= install_muck_activity
  install_solr ||= install_muck_content
  install_muck_comments ||= install_muck_activity || install_muck_blogs || install_muck_raker
  install_tagging ||= install_muck_content
  install_babelphish ||= install_muck_content
  install_file_uploads ||= install_muck_content
  install_geokit ||= install_muck_profiles

end

installed_gems = []

#====================
# Geokit
#====================
if install_geokit
  gem 'geokit'
  plugin 'geokit-rails', :git => "git://github.com/andre/geokit-rails.git"
  
  file_inject 'config/initializers/geokit_config.rb', "default: &DEFAULT", <<-CODE
  require 'geokit'
  CODE
  
  file_inject 'vendor/plugins/geokit-rails/init.rb', "default: &DEFAULT", <<-CODE
  require 'geokit'
  CODE
  
  file_replace 'config/initializers/geokit_config.rb', 'REPLACE_WITH_YOUR_YAHOO_KEY', <<-CODE
  # http://developer.yahoo.com/faq/index.html#appid
  GlobalConfig.yahoo_geo_key
  
  CODE
  
  file_replace 'config/initializers/geokit_config.rb', 'REPLACE_WITH_YOUR_GOOGLE_KEY', <<-CODE
  # http://www.google.com/apis/maps/signup.html
  GlobalConfig.google_geo_key
  
  CODE
  
  puts 'Look in global_config.yml for the urls where you can aquire the keys for the yahoo and google key required to make geo coding work.'
end

#====================
# SMS fu
#====================
if install_sms
  plugin 'sms-fu', :git => "git://github.com/brendanlim/sms-fu.git"
end

#====================
# babelphish
#====================
if install_babelphish || install_everything
  gem 'babelphish'
  installed_gems << 'babelphish'
end

#====================
# muck solr
#====================
if install_solr || install_everything
  gem 'muck-solr', :lib => 'acts_as_solr'
  # TODO add code to install solr config files
  # TODO muck-solr requires muck_raker.rb to be installed in initializers.
  # that file should probably be setup by a rake task in muck-solr and be
  # called muck_solr.rb NOT muck_raker.rb
  installed_gems << 'muck-solr'
end

#====================
# muck raker
#====================
if install_muck_raker || install_everything
  gem 'muck-raker', :lib => 'muck_raker'
  gem "muck-feedbag", :lib => 'feedbag'
  gem "feedzirra"
  gem "nokogiri"
  gem "httparty"
  gem "river"
  
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  
  # Muck raker options
  inform_admin_of_global_feed: true
  enable_raker_comments: true
  enable_raker_shares: true
  
  # Get these values from your Amazon account.  They are required if you wish to access any of Amazon's APIs
  amazon_secret_access_key: ''  # This is the secret value provided by amazon.   This value is hidden by default.
  amazon_access_key_id: ''  # This is your access key id.  This value is not hidden by default.
  amazon_associate_tag: ''
  ecs_to_rss_wishlist: "http://www.example.com/ecs_to_rss-wishlist.xslt"  # url of xslt stylesheet for transforming amazon xml.  This stylesheet is provided by the 'river' gem
  
  # Google ajax api key is optional but recommended by google.  Get one here: http://code.google.com/apis/ajaxsearch/signup.html
  google_ajax_api_key: ''
  show_google_search: true        # Determines whether or not a google search is displayed on the topic page
  load_feeds_on_server: false     # Determines whether feeds on a topic page are loaded on the server or the client.  Loading on the server can take a while
  combine_feeds_on_server: false  # Combines feeds loaded on the server
  CODE
  
  file_insert 'app/views/layouts/global/_head.html.erb', "reset blueprint/liquid_screen.css jquery/jquery.fancybox.css styles frame", <<-CODE
  muck-raker
  CODE
  
  file_inject 'app/views/layouts/global/_head.html.erb', "muck.js", <<-CODE
  muck_raker.js
  CODE
  
  file_append 'Rakefile', <<-CODE
  require 'muck_raker/tasks'
  CODE
  
  installed_gems << 'muck-raker'
  
end

#====================
# muck oauth
#====================
if install_muck_oauth || install_everything
  gem 'muck-oauth', :lib => 'muck_oauth'
  
  file_append 'Rakefile', <<-CODE
  require 'muck_oauth/tasks'
  CODE
  
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  # Oauth
  # Twitter api access: http://www.twitter.com/apps 
  twitter_oauth_key: ""
  twitter_oauth_secret: ""

  # Google api access: http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html#register
  google_oauth_key: ""
  google_oauth_secret: ""

  # Yahoo api access: http://developer.yahoo.com/flickr/
  # yahoo_oauth_key: ""
  # yahoo_oauth_secret: ""

  # Flick api access: http://www.flickr.com/services/apps/create/apply
  # flickr_oauth_key: ""
  # flickr_oauth_secret: ""

  # Linked In api access: https://www.linkedin.com/secure/developer
  linkedin_oauth_key: ""
  linkedin_oauth_secret: ""

  # Friendfeed api access: https://friendfeed.com/account/login?next=%2Fapi%2Fregister
  friendfeed_oauth_key: ""
  friendfeed_oauth_secret: ""  

  # Fire Eagle api access: https://fireeagle.yahoo.net/developer/manage
  # fireeagle_oauth_key: "" 
  # fireeagle_oauth_secret: ""
  CODE
  
  installed_gems << 'muck-oauth'
end

#====================
# muck blogs
#====================
if install_muck_blogs || install_everything
  gem 'muck-blogs', :lib => 'muck_blogs'
  
  file_append 'Rakefile', <<-CODE
  require 'muck_blogs/tasks'
  CODE
  
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  # Blogs
  enable_post_activities: true # Determine whether or not an activity will be added after a user contributes a post.  Requires muck-activities
  CODE

  file 'app/models/blog.rb', <<-CODE
  class Blog < ActiveRecord::Base
    acts_as_muck_blog
  end
  CODE

  installed_gems << 'muck-blogs'
  
end

#====================
# muck content engine
#====================
if install_muck_content || install_everything
  gem 'muck-contents', :lib => 'muck_contents'
  gem 'tiny_mce'
  
  file_append 'Rakefile', <<-CODE
  require 'muck_contents/tasks'
  CODE
  
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  # Content - see muck-contents readme for more information
  enable_auto_translations: false # If enabled all content will be translated into all available languages on each save.  Requires babelphish gem
  content_enable_solr: #{install_solr ? 'true' : 'false'} # requires that solr be installed
  content_git_repository: false # use a backend git repository for source control
  git_repository: '' # path to git repository to use for content version control
  CODE
  
  file 'app/models/content.rb', <<-CODE
  class Content < ActiveRecord::Base
    acts_as_muck_content(
      :git_repository => GlobalConfig.content_git_repository,
      :enable_auto_translations => GlobalConfig.enable_auto_translations,
      :enable_solr => GlobalConfig.content_enable_solr
    )
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
  
  file 'app/controllers/contents_controller.rb', <<-CODE
  class ContentsController < Muck::ContentsController
  end
  CODE
  
  file_inject 'config/routes.rb', "ActionController::Routing::Routes.draw do |map|", <<-CODE
  map.resources :contents
  CODE
  
  file_inject 'app/controllers/application_controller.rb', "class ApplicationController < ActionController::Base", <<-CODE
  acts_as_muck_content_handler
  CODE
  
  installed_gems << 'muck-contents'
end

#====================
# muck shares
#====================
if install_muck_shares || install_everything
  gem 'muck-shares', :lib => 'muck_shares'
  
  file 'app/models/share.rb', <<-CODE
  class Share < ActiveRecord::Base
    acts_as_muck_share
  end
  CODE
  
  file_inject 'app/models/user.rb', 'class User < ActiveRecord::Base', <<-CODE
  acts_as_muck_sharer
  CODE
  
  file_append 'Rakefile', <<-CODE
  require 'muck_shares/tasks'
  CODE

  installed_gems << 'muck-shares'
end

#====================
# muck profile engine
#====================
if install_muck_profiles || install_everything
  gem 'muck-profiles', :lib => 'muck_profiles'
  
  file_append 'Rakefile', <<-CODE
  require 'muck_profiles/tasks'
  CODE
  
  file 'app/models/profile.rb', <<-CODE
  class Profile < ActiveRecord::Base
    acts_as_muck_profile
  end
  CODE
  
  installed_gems << 'muck-profiles'
end

#====================
# muck activity engine
#====================
if install_muck_activity || install_everything
  gem 'muck-activities', :lib => 'muck_activities'
  file_append 'Rakefile', <<-CODE
  require 'muck_activities/tasks'
  CODE
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  # activity configuration
  enable_live_activity_updates: true              # Turns on polling inside the user's activity feed so they constantly get updates from the site
  live_activity_update_interval: 60               # Time between updates to live activity feed in seconds.  Setting this number to low can put quite a bit of strain on your site.
  enable_activity_comments: true                  # Turn on comments inside the activity feed
  enable_activity_file_uploads: true # Turn on file uploads in the activity feed.  Requires that uploader be installed.
  enable_activity_image_uploads: true # Turn on image uploads in the activity feed.  Requires that uploader and muck_albums be installed.
  enable_activity_video_sharing: true # Turn on video sharing in the activity feed.
  CODE
  
  file_insert 'app/views/layouts/global/_head.html.erb', "reset blueprint/liquid_screen.css jquery/jquery.fancybox.css styles frame", <<-CODE
  muck-activities
  CODE
  
  file_inject 'app/views/layouts/global/_head.html.erb', "muck.js", <<-CODE
  muck_activities.js
  CODE
  
  installed_gems << 'muck-activities'
end

#====================
# muck friends engine
#====================
if install_muck_friends || install_everything
  gem 'muck-friends', :lib => 'muck_friends'
  
  file_append 'Rakefile', <<-CODE
  require 'muck_friends/tasks'
  CODE
  
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  # Friend configuration
  # Muck Friends provides a hybrid friend/follow model.  Either mode can be turned off or both can be enabled
  # If only following is enabled then users will be provided the ability to follow, unfollow, and block
  # If only friending is enabled then users will be provided a 'friend request' link and the ability to accept friend requests
  # If both modes are are enabled then users will be able to follow other users.  A mutual follow results in 'friends'.  An unfollow 
  # leaves the other party as just a follower.
  # Note that at least one mode must be enabled or imagine all life as you know it stopping instantaneously and every molecule in your body exploding at the speed of light. 
  enable_friending: true        # If true then friending is enabled.
  enable_following: true        # If true then users can 'follow' each other.  If false then only friend requests will be used.
  enable_friend_activity: true  # If true then friend related activity will show up in the activity feed.  Requires muck-activities gem
  
  CODE

  installed_gems << 'muck-friends'
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
  
  installed_gems << 'cms-lite'
end

#====================
# disguise
#====================
if install_disguise || install_everything
  gem 'disguise'
  file_append 'Rakefile', <<-CODE
  require 'disguise/tasks'
  CODE
  rake('disguise:setup')
  
  file_inject 'config/global_config.yml', "default: &DEFAULT", <<-CODE
  #theme configuration
  use_domain_for_themes: false                    # Setting for the disguise plugin.  Themes can be set in the admin UI or determined at run time by the domain name.
  CODE
  
  installed_gems << 'disguise'
end


#====================
# uploader
#====================
if install_file_uploads || install_everything
  
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
                                      :large => "660>" },
                        :default_url => "/images/profile_default.jpg",
                        :storage => :s3,
                        :s3_credentials => AMAZON_S3_CREDENTIALS,
                        :bucket => "assets.\#{GlobalConfig.application_url}",
                        :s3_host_alias => "assets.\#{GlobalConfig.application_url}",
                        :convert_options => {
                           :all => '-quality 80'
                         }
                      },
                      :s3_path => ':id_partition/:style/:basename.:extension'
  
  end
  CODE
  
  installed_gems << 'uploader'
  
  rake('uploader:sync')
end


#====================
# muck comments
#====================
if install_muck_comments || install_everything

  # nested set is required for comments
  gem "awesome_nested_set"
  gem "sanitize"
  
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

  file 'app/controllers/comments_controller.rb', <<-CODE
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
  
  installed_gems << 'muck-comments'
end

#====================
# muck invites
#====================
if install_muck_invites || install_everything
  
  gem 'muck-invites', :lib => 'muck_invites'
  
  file_insert 'app/views/layouts/global/_head.html.erb', "reset blueprint/liquid_screen.css jquery/jquery.fancybox.css styles frame", <<-CODE
  muck-invites
  CODE
  
  file_inject 'app/models/user.rb', 'class User < ActiveRecord::Base', <<-CODE
  acts_as_muck_inviter
  CODE
  
  file 'app/models/invite.rb', <<-CODE
  class Invite < ActiveRecord::Base
    acts_as_muck_invite
  end
  CODE
  
  file 'app/models/invitee.rb', <<-CODE
  class Invitee < ActiveRecord::Base
    acts_as_muck_invitee
  end
  CODE
  
  
  installed_gems << 'muck-invites'
  
end


#====================
# muck.rake
#====================
file 'lib/tasks/muck.rake', <<-CODE
require 'rake'
begin
  require 'git'
rescue LoadError
  puts "git gem not installed.  If git functionality is required run 'sudo gem install git'"
end
require 'fileutils'

namespace :muck do
  
  def muck_gems
    ["#{installed_gems.join('","')}"]
  end
  
  desc 'Translate app'
  task :translate => :environment do
    puts 'translating'
    system("babelphish -o -y #{RAILS_ROOT}/config/locales/en.yml")
  end

end
CODE

#====================
# tagging
#====================
if install_tagging || install_everything
  gem 'acts-as-taggable-on'
  file_inject('app/helpers/application_helper.rb', 'module ApplicationHelper', 'include TagsHelper')
  file_inject('app/models/user.rb', 'class User < ActiveRecord::Base', 'acts_as_tagger')
  run "script/generate acts_as_taggable_on_migration"
end

#====================
# Sync in assets from the gems
#====================
rake('muck:sync')

#====================
# Run any needed migrations
#====================
rake('db:migrate')


puts "================================================================================"
puts "SUCCESS!"
puts "================================================================================"
puts "To populate the database with feeds and defaults for raker run: "
puts " rake muck:raker:db:populate"
puts ""
puts "Or to populate the database with only the defaults and no feeds run: "
puts "muck:raker:db:bootstrap_services"
puts ""
puts "Update existing default data with defaults specific to muck raker"
puts "muck:raker:db:populate"
