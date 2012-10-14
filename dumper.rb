#encoding:utf-8
require "bundler"
require "open-uri"

Bundler.require(:default)

DataMapper.setup(:default, 'sqlite:songs.db')

class Song
  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :artist, String
  property :wii_number, String
  property :utaidashi, String
  property :genre, String
end

Song.auto_upgrade!

module Dumper

  def self.full_url(page)
    "http://joysound.com" + page
  end

  def self.extract_song(page)
    doc = Nokogiri::HTML(page)
    title = doc.css(".wiiTable .type02").text
    artist = doc.css(".artist p").text
    genre = doc.css(".musicDetailsBlock tr:nth-child(2) a").text
    wii_number = doc.css(".wiiTable td:nth-child(2)").text[/\d+/]
    utaidashi = doc.css(".musicDetailsBlock tr:nth-child(3) td").text
    {title: title, artist: artist, genre: genre, wii_number: wii_number, utaidashi: utaidashi}
  end

  # Takes: One full url of any page of an artist.
  # Returns: A hash containing an array of songs on this page and an url
  # to the next page, if available.
  def self.extract_artist_page(page)
    puts "Extracting #{page}"
    begin
      html = open(page).read
    rescue
      tries ||= 0
      tries += 1
      retry unless tries > 10 # you have to stop somewhere...
    end
    doc = Nokogiri::HTML(html)
    links = doc.css(".title a").map{|link| full_url(link.attribute("href"))}
    songs = []

    begin
      hydra = Typhoeus::Hydra.new(max_concurrency: 2) # Joysound is slow...
      failed = []

      links.each do |link|
        req = Typhoeus::Request.new(link)
        req.on_complete do |response|
          if(response.success?)
            songs.push(extract_song(response.body))
          else
            failed.push(link)
          end
        end
        hydra.queue(req)
      end

      hydra.run
      links = failed
    end while(links.count != 0)

    next_url = check_for_next_page(doc)

    {songs: songs, next_url: next_url}
  end

  def self.extract_artist_pages(page)
    follow_pages(page, :extract_artist_page)
  end

  def self.check_for_next_page(doc)
    #Check if there is a next page
    if doc.text["次の20件"] then 
      next_url = full_url(doc.css(".transitionLinks03 li:last-of-type a").attribute("href"))
    else
      next_url = nil
    end
    next_url
  end

  def self.follow_pages(startPage, method)
    songs = []
    current_page = startPage
    begin
      res = self.send(method, current_page)
      current_page = res[:next_url]
      songs += res[:songs]
    end while(current_page)
    songs
  end

  def self.extract_artists_page(page)
    begin
      html = open(page).read
    rescue
      tries ||= 0
      tries += 1
      puts tries
      retry unless tries > 10 # you have to stop somewhere...
    end
    doc = Nokogiri::HTML(html)
    songs = []
    links = doc.css(".wii a")
    links.each do |link|
      songs += extract_artist_pages(full_url(link.attribute("href")))
    end
    next_url = check_for_next_page(doc)

    {songs: songs, next_url: next_url}
  end

  def self.extract_artists_pages(page)
    follow_pages(page, :extract_artists_page)
  end
end
