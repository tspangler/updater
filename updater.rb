# updater.rb
# pulls in updates from my Twitter and Github accounts and saves them to a flat file
# run by a cron job

require 'rubygems'
require 'hpricot'
require 'open-uri'

# Do Twitter first...
twitter_statuses = Hpricot.XML(open('http://twitter.com/statuses/user_timeline.xml?screen_name=symsonic&count=5'))

f = File.open('twitter.inc', 'w')
  twitter_statuses.search('status').each do |tweet|
    f.puts "<li><a href='http://twitter.com/symsonic/status/#{tweet.search("id").first.inner_html}'>#{tweet.search("text").inner_html}</a></li>"
  end
f.close

# ...and move on to Github
github_feed = Hpricot.XML(open('http://github.com/tspangler.atom'))

f = File.open('github.inc', 'w')
  github_feed.search('title').each do |event|
    # Some basic filters since we only really want commits and pushes
    if event.inner_html.index('commit') || event.inner_html.index('push') || (event.inner_html.index('created') && !event.inner_html.index('wiki') && !event.inner_html.index('gist')) && !event.inner_html.index('activity')    
      # Strip out all redundant mentions of my username
      f.puts "<li>#{event.inner_html.gsub(/tspangler[\/]?/, '').strip}</li>"
      
      # linkify project names
      # "pushed to branch at project_name"
      
    end
  end
f.close