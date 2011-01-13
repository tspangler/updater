# updater.rb
# pulls in updates from my Twitter and Github accounts and saves them to a flat file
# run by a cron job

require 'rubygems'
require 'hpricot'
require 'open-uri'

def urlify_and_tweetify(str)
  str.scan(/http:\/\/[\.\/?&\-\w]+\.[\w]+[\/\.?&\-\w]+/).each do |s|
    str.gsub!(s, '<a href="' + s + '" target="_blank">' + s + '</a>')
  end
    
  # Now tweetify...
  str.scan(/@[_\w]+/).each do |s|
    s.slice!(0) # Chop off the initial @ from the username
    
    # Yes, this is dumb but I want the @ to be part of the link, like it is on Twitter itself
    str.gsub!('@' + s, '<a href="http://twitter.com/' + s + '" target="_blank">' + '@' + s + '</a>')
  end

  str
end

def fix_entities(str)
  str.scan(/&amp;[a-z]+;/).each do |sub|
    str.gsub!(sub, sub.gsub('&amp;', '&'))
  end

  str
end

# Do Twitter first...
begin
twitter_statuses = Hpricot.XML(open('http://twitter.com/statuses/user_timeline.xml?screen_name=symsonic&count=5'))

f = File.open('twitter.inc', 'w')
  twitter_statuses.search('status').each do |tweet|
    tweet_id = tweet.search('id').first.inner_html
    tweet_text = urlify_and_tweetify(fix_entities(tweet.search('text').inner_html))

    f.puts "<li>#{tweet_text}</li>"
  end
f.close

rescue OpenURI::HTTPError
  puts 'Error opening Twitter feed.'
end

# ...and move on to Github
github_feed = Hpricot.XML(open('https://github.com/tspangler.atom'))

f = File.open('github.inc', 'w')
  github_feed.search('title').each do |event|
    # Some basic filters since we only really want commits and pushes.
    # There are definitely much better ways to do this but I'm doing it quick and dirty.
    if event.inner_html.index('fork') || event.inner_html.index('commit') || event.inner_html.index('push') || (event.inner_html.index('created') && !event.inner_html.index('wiki') && !event.inner_html.index('gist')) && !event.inner_html.index('activity')    
      # Strip out all redundant mentions of my username
      f.puts "<li>#{event.inner_html.gsub(/tspangler[\/]?/, '').strip}</li>"
      # TODO: Linkify project names
    end
  end
f.close