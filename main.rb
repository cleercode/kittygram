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
    Twitter::Search.new('cat OR kitten source:Instagram') \
                   .lang('en') \
                   .page(page) \
                   .per_page(per_page) \
                   .each do |r|
      results << {
                'url' => r.text.scan(/http:\/\/instagr.am\/p\/\S+\s*/).first,
                'text' => r.text.split(/http:\/\/instagr.am\/p\/\S+\s*/).first.gsub('Just posted a photo', ''),
                'photo' => get_photo(r.text.scan(/http:\/\/instagr.am\/p\/\S+\s*/).first),
                'avatar' => r.profile_image_url,
                'user' => r.from_user
                }
    end
  end
  results
end

get '/index.html' do
  @results = fetch_stream(1, 10)
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
    %title Kittygram!
    %link{:href => "http://yui.yahooapis.com/2.8.0r4/build/reset/reset-min.css", :rel => "stylesheet"}
    %link{:href => "style.css", :rel => "stylesheet"}
  %body
    #container
      %h1 Kittygram!
      #content= yield
      #footer
        %p
          Kittygram shows recent pictures of cats from around the world.
          %br
          Powered by Sinatra, Heroku, Twitter, and Instagram.
          %br
          Built by
          %a{:href => 'http://chrsl.net'} Chris Lee
      #fade
    %script{:src => "https://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js", :type => "text/javascript"}
    %script{:src => "jquery.cycle.all.min.js", :type => "text/javascript"}
    %script{:src => "script.js", :type => "text/javascript"}

@@ index
%ul#results
  - @results.each do |r|
    %li.result[r]
      %img.photo{:src => r['photo']}
      .info
        %a{:href => 'http://twitter.com/' + r['user']}
          %img.avatar{:src => r['avatar']}
        %ul.details
          %li.user
            %a{:href => 'http://twitter.com/' + r['user']}= '@' + r['user']
          %li.text= r['text']