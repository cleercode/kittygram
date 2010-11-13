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
                'time' => r.created_at
                }
    end
  end
  results
end

def time_ago_in_words(from_time, to_time = Time.now, include_seconds = false, options = {})
  from_time = from_time.to_time if from_time.respond_to?(:to_time)
  to_time = to_time.to_time if to_time.respond_to?(:to_time)
  distance_in_minutes = (((to_time - from_time).abs)/60).round
  distance_in_seconds = ((to_time - from_time).abs).round

  I18n.with_options :locale => options[:locale], :scope => :'datetime.distance_in_words' do |locale|
    case distance_in_minutes
      when 0..1
        return distance_in_minutes == 0 ?
               locale.t(:less_than_x_minutes, :count => 1) :
               locale.t(:x_minutes, :count => distance_in_minutes) unless include_seconds

        case distance_in_seconds
          when 0..4   then locale.t :less_than_x_seconds, :count => 5
          when 5..9   then locale.t :less_than_x_seconds, :count => 10
          when 10..19 then locale.t :less_than_x_seconds, :count => 20
          when 20..39 then locale.t :half_a_minute
          when 40..59 then locale.t :less_than_x_minutes, :count => 1
          else             locale.t :x_minutes,           :count => 1
        end

      when 2..44           then locale.t :x_minutes,      :count => distance_in_minutes
      when 45..89          then locale.t :about_x_hours,  :count => 1
      when 90..1439        then locale.t :about_x_hours,  :count => (distance_in_minutes.to_f / 60.0).round
      when 1440..2529      then locale.t :x_days,         :count => 1
      when 2530..43199     then locale.t :x_days,         :count => (distance_in_minutes.to_f / 1440.0).round
      when 43200..86399    then locale.t :about_x_months, :count => 1
      when 86400..525599   then locale.t :x_months,       :count => (distance_in_minutes.to_f / 43200.0).round
      else
        distance_in_years           = distance_in_minutes / 525600
        minute_offset_for_leap_year = (distance_in_years / 4) * 1440
        remainder                   = ((distance_in_minutes - minute_offset_for_leap_year) % 525600)
        if remainder < 131400
          locale.t(:about_x_years,  :count => distance_in_years)
        elsif remainder < 394200
          locale.t(:over_x_years,   :count => distance_in_years)
        else
          locale.t(:almost_x_years, :count => distance_in_years + 1)
        end
    end
  end
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
    %link{:src => "http://fonts.googleapis.com/css?family=Reenie+Beanie&subset=latin", :rel => "stylesheet"}
    %link{:src => "style.css", :rel => "stylesheet"}
    %link(rel="stylesheet" href="http://yui.yahooapis.com/2.8.0r4/build/reset/reset-min.css")  
    %link(rel="stylesheet" href="http://fonts.googleapis.com/css?family=PT+Sans+Caption:regular,bold&subset=cyrillic")  
    %link(rel="stylesheet" href="style.css")
  %body
    #container
      %h1 Instagramline
      #content= yield
      #footer
        %p Instagramline is powered by Sinatra, Heroku, Twitter, and Instagram.

@@ index
- @results.each do |r|
  .result[r]
    %a{:href => '/'}
      %img.photo{:src => r['photo']}
    .info
      %a{:href => 'http://twitter.com/' + r['user']}
        %img.avatar{:src => r['avatar']}
      %ul.details
        %li.user
          %a{:href => 'http://twitter.com/' + r['user']}= '@' + r['user']
        %li.text= r['text']
        %li.time= r['time']