require "./sattva"
require 'rack/reverse_proxy'

use Rack::ReverseProxy do
  reverse_proxy_options preserve_host: true
  reverse_proxy '/check-ip', 'https://api.ipify.org/'
  reverse_proxy '/', 'https://gives.co/'
end

run Sattva::Application.new
