require "./sattva"
require 'rack/reverse_proxy'

use Rack::ReverseProxy do
  reverse_proxy_options preserve_host: true, matching: :first
  reverse_proxy /^\/check-ip(.*)$/, 'https://api.ipify.org$1'
  reverse_proxy '/', 'https://gives.co/'
end

run Sattva::Application.new
