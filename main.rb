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
    Twitter::Search.new('cat OR kitten -"not cat" source:Instagram') \
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


get '/' do
  @results = fetch_stream(1, 10)
  haml :index
end

get '/index.html' do
  redirect '/'
end

__END__

@@ layout
!!!
%html
  %head
    %title Kittygram!
    %meta{:"http-equiv" => "Content-Type", :content => "text/html; charset=utf-8"} 
    %meta{:name => "keywords", :content => "instagram instagr.am twitter tweet tweets cat cats"} 
    %meta{:name => "description", :content => "Kittygram shows recent pictures of cats from around the world."}
    %meta{:content => "Kittygram!", :property => "og:title"}
    %meta{:content => "website", :property => "og:type"}
    %meta{:content => "http://kittygram.heroku.com/", :property => "og:url"}
    %meta{:content => "Kittygram shows recent pictures of cats from around the world.", :property => "og:description"}
    %meta{:content => "1090230245", :property => "fb:admins"}
    %link{:href => "http://yui.yahooapis.com/2.8.0r4/build/reset/reset-min.css", :rel => "stylesheet"}
    %link{:href => "style.css", :rel => "stylesheet"}
    :plain
      <script type="text/javascript">

        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-19583432-2']);
        _gaq.push(['_trackPageview']);

        (function() {
          var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
          ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
          var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();

      </script>
  %body
    #container
      %h1 Kittygram!
      #content= yield
      #footer
        %a.twitter-share-button{"data-count" => "horizontal", "data-text" => "Kittygram: Cute cat photos live from Twitter.", "data-url" => "http://kittygram.heroku.com", :"data-via" => "cleerview", :href => "http://twitter.com/share"} Tweet
        %iframe{:allowTransparency => "true", :frameborder => "0", :scrolling => "no", :src => "http://www.facebook.com/plugins/like.php?href=http%3A%2F%2Fkittygram.heroku.com%2F&layout=button_count&show_faces=true&width=110&action=like&colorscheme=light&height=21", :style => "border:none; overflow:hidden; width:110px; height:20px;"}
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
    %script{:src => "http://platform.twitter.com/widgets.js", :type => "text/javascript"}
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