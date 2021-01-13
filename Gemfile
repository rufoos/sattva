source "https://rubygems.org"

# ruby web interface
gem "rack"

gem "rack-reverse-proxy", require: "rack/reverse_proxy"

# server, to run: bundle exec thin start
gem "thin"

group :development do
  gem 'capistrano-thin'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
end
