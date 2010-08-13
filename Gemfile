source :gemcutter

# Wesabe gems
# gem 'keyword_search',  '1.3.99'  # in vendor/gems
gem 'chronic',         '0.2.3'

# Regular gems
gem 'rails',           '3.0.0.rc'

platforms :mri_18 do
  gem "oniguruma", :require => 'oniguruma'
end

gem 'fastercsv'
gem 'riddle'
gem 'memcache-client',            :require => 'memcache'
gem 'mime-types',                 :require => 'mime/types'
gem 'rest-client',                :require => 'rest_client'
gem 'rubyzip',                    :require => 'zip/zip'
gem 'libxml-ruby',     '=1.1.3',  :require => 'xml/libxml'
gem 'daemons'
gem 'rdoc'
gem 'delayed_job',     '2.1.0.pre'
gem 'thor' # for imports
gem 'mongrel' # faster development server
gem 'rchardet'

group :development do
  gem 'mysql'           # in production: apt-get install libmysql-ruby
end

group :test do
  gem 'webmock'
  gem 'rspec-rails',   '>= 2.0.0.beta.17'
  gem 'rspec',         '>= 2.0.0.beta.17'
  gem 'ruby-debug'
  gem 'machinist'
  gem 'faker'
end
