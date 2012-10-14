require_relative "dumper.rb"

# Clear DB
Song.auto_migrate!

# Get start pages
doc = Nokogiri::HTML(open('http://joysound.com/ex/search/'))
start_pages = doc.css("#main :nth-child(1) .searchBoxAreaInner a")

start_pages.each do |page|
  puts "Trying #{page}"
  songs = Dumper.extract_artists_pages(Dumper.full_url(page.attribute("href")))
  puts songs
  songs.each do |song_data|
    Song.create(song_data)
  end
end
