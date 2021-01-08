require "./sattva"
require 'rack/reverse_proxy'

use Rack::ReverseProxy do
  reverse_proxy_options preserve_host: true
  reverse_proxy '/', 'https://gives.co/'
  reverse_proxy '/check-ip', 'https://api.ipify.org/'
end

run Sattva::Application.new
