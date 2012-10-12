require "bundler"
require "open-uri"

Bundler.require

module Dumper
  def self.extract_song(page)
    doc = Nokogiri::HTML(open(page))
    title = doc.css(".wiiTable .type02").text
    artist = doc.css(".artist p").text
    genre = doc.css(".musicDetailsBlock tr:nth-child(2) a").text
    wii_number = doc.css(".wiiTable td:nth-child(2)").text[/\d+/]
    {title: title, artist: artist, genre: genre, wii_number: wii_number}
  end

  def self.extract_artist_page(page)
    doc = Nokogiri::HTML(open(page))
    links = doc.css(".title a")
    songs = links.map do |link|
      extract_song("http://joysound.com" + link.attribute("href"))
    end
    songs
  end
end
