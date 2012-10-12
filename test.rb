#encoding:utf-8
require "minitest/spec"
require "minitest/autorun"

require_relative "dumper.rb"

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb
end

describe Dumper do
  it "should read a page and extract a song out of it" do
    VCR.use_cassette("first_kiss") do
      page = "http://joysound.com/ex/search/song.htm?gakkyokuId=283053"
      song = Dumper.extract_song(page)
      song[:title].must_equal("FIRST KISS")
      song[:artist].must_equal("あぁ!")
      song[:genre].must_equal("J-POP/グループ")
      song[:wii_number].must_equal("31864")
    end
  end

  it "should take one artist page and extract all songs from it" do
    VCR.use_cassette("beatles_first_page") do
      page = "http://joysound.com/ex/search/artist.htm?artistId=3917&wiiall=1"
      res = Dumper.extract_artist_page(page)
      songs = res[:songs]
      songs.count.must_equal(20)
      next_url = res[:next_url]
      next_url.wont_be_nil
    end
  end

  it "should stop giving new urls when the end is reached" do
    VCR.use_cassette("meat_loaf_only_page") do
      page = "http://joysound.com/ex/search/artist.htm?artistId=3502&wiiall=1"
      res = Dumper.extract_artist_page(page)
      songs = res[:songs]
      songs.count.must_equal(1)
      next_url = res[:next_url]
      next_url.must_equal(nil)
    end
  end

  it "should take the first artist page and extract all songs from the artist" do
    VCR.use_cassette("beatles_all_pages") do
      page = "http://joysound.com/ex/search/artist.htm?artistId=3917&wiiall=1"
      songs = Dumper.extract_artist_pages(page)
      songs.count.must_equal(156)
    end
  end
end
