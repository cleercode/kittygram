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
                'text' => r.text.split(/http:\/\/instagr.am\/p\/\S+\s*/).first.gsub('Just posted a photo', ''),
                'photo' => get_photo(r.text.scan(/http:\/\/instagr.am\/p\/\S+\s*/).first),
                'avatar' => r.profile_image_url,
                'user' => r.from_user,
                'geo' => r.geo,
                'time' => r.created_at
                }
    end
  end
  results
end

get '/index.html' do
  @results = fetch_stream(1, 1)
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
    %title Instagramline
    %link{:src => "http://yui.yahooapis.com/2.8.0r4/build/reset/reset-min.css", :rel => "stylesheet"}
    %link{:src => "http://fonts.googleapis.com/css?family=PT+Sans+Caption:regular,bold&subset=cyrillic", :rel => "stylesheet"}
    %link{:src => "style.css", :rel => "stylesheet"}
    %link(rel="stylesheet" href="http://yui.yahooapis.com/2.8.0r4/build/reset/reset-min.css")  
    %link(rel="stylesheet" href="http://fonts.googleapis.com/css?family=PT+Sans+Caption:regular,bold&subset=cyrillic")  
    %link(rel="stylesheet" href="style.css")
  %body
    %h1 Instagramline
    #content= yield

@@ index
- @results.each do |r|
  .result[r]
    %a{:href => '/'}
      %img.photo{:src => r['photo']}
    .info
      %img.avatar{:src => r['avatar']}
      %ul.details
        %li.user
          %a{:href => 'http://twitter.com/' + r['user']}= '@' + r['user']
        %li.text= r['text']
        %li.geo= r['geo']