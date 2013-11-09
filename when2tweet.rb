#!/usr/bin/ruby
# encoding: utf-8
# = when2tweet.rb
#
# Author:: ajramos
#
# == Description
# * Migrated the script to RubyScripts API 1.1 from a shell script
#   I found somewhere I just can't find again.
# * Script outputs the 4 top timeframes to reach your top 25 followers
#   during their most active timeframe.
#
# === Usage:
#
# Fill up the configuration data at the variables:
#
# - consumer_key, consumer_secret: credentials of your application.
# - access_token, access_secret: credentials for using authenticated
#   twitter API methods
# - my_handle: your twitter alias

require 'json'
require 'oauth'
require 'time'

def classify(time, list)
# print "Change: time_str: #{time.strftime('%Y-%m-%d %H:%M')}"
  if time.min < 20
    time_str = time.strftime('%H:00')
  elsif time.min < 40
    time_str = time.strftime('%H:20')
  else # <60
    time_str = time.strftime('%H:40')
  end

  list[time_str] = list[time_str].nil? ? 1 :  list[time_str] + 1
  # puts " into #{time_str}"
  list
end

consumer_key = 'YOUR_APP_CONSUMER_KEY_HERE'
consumer_secret = 'YOUR_APP_CONSUMER_SECRET_HERE'
twitter_api_url = 'https://api.twitter.com'

access_token = 'YOUR_ACCESS_TOKEN_HERE'
access_secret = 'YOUR_ACCESS_SECRET_HERE'

my_handle = 'YOUR_TWITTER_USERNAME_HERE' # RubyScripts Login
followers_ids_url = "/1.1/followers/ids.json?screen_name=#{my_handle}"
users_lookup_ids_url = '/1.1/users/lookup.json?include_entities=true&user_id='
users_timeline_url = '/1.1/statuses/user_timeline.json'
users_timeline_url += '?include_entities=true&include_rts=true&screen_name='

@consumer = OAuth::Consumer.new(consumer_key,
                                consumer_secret,
                                site: twitter_api_url)

@access_token = OAuth::AccessToken.new(@consumer,
                                       access_token,
                                       access_secret)

puts 'Getting followers id'
response = @access_token.get(followers_ids_url)

follower_ids = JSON.parse(response.body)['ids']    # <5000 followers

users_data = {}
puts "Getting followers(size: #{follower_ids.size}) of my followers"
follower_ids.each do |follower_id|

  response = @access_token.get(users_lookup_ids_url + follower_id.to_s)
  user_data = JSON.parse(response.body)[0]
  users_data[user_data['screen_name']] = user_data['followers_count']

end

puts 'Get top 25 of my followers with more followers'

# top 25 followers
vip_followers = users_data.sort_by { |keys, value| value }.reverse[0..25]

tweets_ts_wd = {}
tweets_ts_we = {}
total_tweets = 0
puts 'Getting timelines'
vip_followers.each do |vip_follower|
  puts "Getting tweets of #{vip_follower.inspect}"
  response = @access_token.get(users_timeline_url + vip_follower[0])

  tweets = JSON.parse(response.body)

  tweets.each do |tweet|
    ts =  Time.parse(tweet['created_at'])
    total_tweets += 1
    if ts.saturday? || ts.sunday?
      tweets_ts_we = classify(ts, tweets_ts_we)
    else
      tweets_ts_wd = classify(ts, tweets_ts_wd)

    end

  end

end

tweets_ts_wd.each { |k, v| tweets_ts_wd[k] = v.to_f / total_tweets }
tweets_ts_we.each { |k, v| tweets_ts_we[k] = v.to_f / total_tweets }

tweets_ts_wd = tweets_ts_wd.sort_by { |k, v| v }.reverse![0...4]
tweets_ts_we = tweets_ts_we.sort_by { |k, v| v }.reverse![0...4]

puts 'During the week is best to tweet at:'
tweets_ts_wd.each do |tweets_ts|
  puts sprintf('%2.2f%% Activity at %s', tweets_ts[1] * 100, tweets_ts[0])
end
puts '------------------------------------'
puts 'Weekends is best at:'
tweets_ts_we.each do |tweets_ts|
  puts sprintf('%2.2f%% Activity at %s', tweets_ts[1] * 100, tweets_ts[0])
end
