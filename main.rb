require 'rubygems'
require 'sinatra'
require 'instagram'
require 'haml'
require 'dalli'
require 'yajl'
CACHE = Dalli::Client.new

Instagram.configure do |config|
  config.client_id = ENV['INSTAGRAM_ID']
  config.client_secret = ENV['INSTAGRAM_SECRET']
end

def getPhotos
  photos = Instagram.tag_recent_media('cat')
  photos.find_all{ |photo| photo.filter != nil }.map { |photo| photo.images.low_resolution.url}
end

get '/' do
  # @results = getPhotos()
  @results = CACHE.fetch('cats', 900) { Instagram.tag_recent_media('cat') }
  haml(:index, { :ugly => true })
end