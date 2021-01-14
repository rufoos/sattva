require 'rack/reverse_proxy'

reverse_host = ENV['REVERSE_PROXY_HOST']
unless reverse_host
  raise "Environment variable REVERSE_PROXY_HOST is not defined"
end
use Rack::ReverseProxy do
  reverse_proxy_options preserve_host: true, matching: :first
  reverse_proxy /^\/check-ip(.*)$/, 'https://api.ipify.org$1'
  reverse_proxy '/', reverse_host
end

app = proc do |env|
  [200, {'Content-Type' => 'text/html'}, ["<h1>It works!<h1>"]]
end
run app
