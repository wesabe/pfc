source :gemcutter

# Regular gems
gem 'rails',             '3.0.1'
gem 'resque',            '1.10.0'
gem 'system_timer'
gem 'daemon_controller', '0.2.5'


platforms :mri_18 do
  gem "oniguruma", :require => 'oniguruma'
end

gem 'chronic',           '0.2.3'
gem 'fastercsv'
gem 'memcache-client',              :require => 'memcache'
gem 'mime-types',                   :require => 'mime/types'
gem 'rest-client',                  :require => 'rest_client'
gem 'rubyzip',                      :require => 'zip/zip'
gem 'libxml-ruby',       '=1.1.3',  :require => 'xml/libxml'
gem 'daemons'
gem 'rdoc'
gem 'thor' # for imports
gem 'unicorn' # faster development server
gem 'rchardet'
gem 'iconv'

group :development do
  gem 'mysql'           # in production: apt-get install libmysql-ruby
end

group :test do
  gem 'webmock'
  gem 'rspec-rails',     '>= 2.0.1'
  gem 'ruby-debug'
  gem 'machinist'
  gem 'faker'
end
