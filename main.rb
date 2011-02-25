require 'rubygems'
require 'sinatra'
require 'instagram'
require 'haml'
require 'dalli'
CACHE = Dalli::Client.new

Instagram.configure do |config|
  config.client_id = ENV['INSTAGRAM_ID']
  config.client_secret = ENV['INSTAGRAM_SECRET']
end

get '/' do
  # @results = Instagram.tag_recent_media('cat')
  @results = CACHE.fetch('cats', 900) { Instagram.tag_recent_media('cat') }
  haml(:index, { :ugly => true })
end