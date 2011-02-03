require 'rubygems'
require 'sinatra'
require 'haml'
require 'twitter'
require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'json'
require 'dalli'
CACHE = Dalli::Client.new

# Given Instagram URL, return the image URL
def get_photo(url)
  uri = URI.parse(URI.encode('http://instagr.am/api/v1/oembed/?url=' + url))
  response = Net::HTTP.get_response uri
  if response.class == Net::HTTPOK
    data = JSON.parse response.body
    return data['url']
  else
    return nil
  end
end

# Search Twitter for Instagrams
def fetch_stream(num_pages, per_page)
  results = []
  search = Twitter::Search.new
  (1..num_pages).each do |page|
    Twitter::Search.new.q('cat OR kitten -"not cat" source:Instagram') \
                   .lang('en') \
                   .page(page) \
                   .per_page(per_page) \
                   .each do |r|
      if (url = r.text.scan(/http:\/\/instagr.am\/p\/\S+\s*/).first and
          photo = get_photo(url))
          results << {
                    'url' => url,
                    'text' => r.text.split(/http:\/\/instagr.am\/p\/\S+\s*/).first.gsub('Just posted a photo', ''),
                    'photo' => photo,
                    'avatar' => r.profile_image_url,
                    'user' => r.from_user
                    }
      end
    end
  end
  results
end

get '/' do
  # @results = fetch_stream(1, 10)
  @results = CACHE.fetch('cats', 900) { fetch_stream(1, 10) }
  haml(:index, { :ugly => true })
end