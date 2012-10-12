#encoding:utf-8
require "bundler"
require "open-uri"

Bundler.require

module Dumper

  def self.full_url(page)
    "http://joysound.com" + page
  end

  def self.extract_song(page)
    doc = Nokogiri::HTML(open(page))
    title = doc.css(".wiiTable .type02").text
    artist = doc.css(".artist p").text
    genre = doc.css(".musicDetailsBlock tr:nth-child(2) a").text
    wii_number = doc.css(".wiiTable td:nth-child(2)").text[/\d+/]
    {title: title, artist: artist, genre: genre, wii_number: wii_number}
  end

  # Takes: One full url of any page of an artist.
  # Returns: A hash containing an array of songs on this page and an url
  # to the next page, if available.
  def self.extract_artist_page(page)
    doc = Nokogiri::HTML(open(page))
    links = doc.css(".title a")
    songs = links.map do |link|
      extract_song(full_url(link.attribute("href")))
    end

    #Check if there is a next page
    if doc.text["次の20件"] then 
      next_url = full_url(doc.css(".transitionLinks03 li:last-of-type a").attribute("href"))
    else
      next_url = nil
    end

    {songs: songs, next_url: next_url}
  end

  def self.extract_artist_pages(page)
    songs = []
    current_page = page
    begin
      res = extract_artist_page(current_page)
      current_page = res[:next_url]
      songs += res[:songs]
    end while(current_page)
    songs
  end
end
