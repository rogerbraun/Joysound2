#encoding:utf-8
require "minitest/spec"
require "minitest/autorun"

require_relative "dumper.rb"

describe Dumper do
  it "should read a page and extract a song out of it" do
    page = "http://joysound.com/ex/search/song.htm?gakkyokuId=283053"
    song = Dumper.extract_song(page)
    song[:title].must_equal("FIRST KISS")
    song[:artist].must_equal("あぁ!")
    song[:genre].must_equal("J-POP/グループ")
    song[:wii_number].must_equal("31864")
  end

  it "should take one artist page and extract all songs from it" do
    page = "http://joysound.com/ex/search/artist.htm?artistId=3917&wiiall=1"
    songs = Dumper.extract_artist_page(page)
    songs.count.must_equal(20)
  end

  it "should take the first artist page and extract all songs from the artist" do

  end
end
