require 'rack/reverse_proxy'

RACK_ENV = ENV['RACK_ENV'] || 'development' unless defined?(RACK_ENV)
is_production = RACK_ENV == 'production'

ObjectSpace.each_object(Thin::Runner) { |obj| @config = obj.options }
Thin::Logging.log_msg("Starting reverse proxy (#{RACK_ENV}) on #{@config[:port]}")
use Rack::ReverseProxy do
  reverse_proxy_options preserve_host: true, matching: :first
  reverse_proxy /^\/check-ip(.*)$/, 'https://api.ipify.org$1'
  reverse_proxy '/', is_production ? 'https://give.asia/' : 'https://gives.co/'
end

app = proc do |env|
  [200, {'Content-Type' => 'text/html'}, ["<h1>It works!<h1>"]]
end
run app
