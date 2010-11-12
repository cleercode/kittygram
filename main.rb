require 'rubygems'
require 'sinatra'
require 'haml'
require 'twitter'
require 'nokogiri'
require 'open-uri'

# Given Instagram URL, return the image URL
def get_photo(url)
  doc = Nokogiri::HTML(open(url))
  doc.at_css('img.photo')['src']
end

# Search Twitter for Instagrams
def fetch_stream(num_pages, per_page)
  results = []
  (1..num_pages).each do |page|
    Twitter::Search.new('http source:Instagram') \
                   .lang('en') \
                   .page(page) \
                   .per_page(per_page) \
                   .each do |r|
      results << {
                'url' => r.text.scan(/http:\/\/instagr.am\/p\/\S+\s*/).first,
                'text' => r.text.split(/http:\/\/instagr.am\/p\/\S+\s*/).first,
                'photo' => get_photo(r.text.scan(/http:\/\/instagr.am\/p\/\S+\s*/).first),
                'avatar' => r.profile_image_url,
                'user' => r.from_user,
                'geo' => r.geo
                }
    end
  end
  results
end

get '/index.html' do
  @results = fetch_stream(5, 10)
  haml :index
end

get '/' do
  redirect '/index.html'
end

__END__

@@ layout
!!!
%html
  %head
    %title Instagram Timeline
  %body
    %h1 Instagram
    #content= yield

@@ index
- @results.each do |r|
  .result[r]
    %img{:src => r['photo']}
    %img{:src => r['avatar']}
    %p= r['user']
    %p= r['text']
    %p= r['geo']