#encoding:utf-8
require "minitest/spec"
require "minitest/autorun"

require_relative "dumper.rb"
Bundler.require(:default, :test)

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb
end

describe Dumper do
  it "should read a page and extract a song out of it" do
    VCR.use_cassette("first_kiss") do
      page = "http://joysound.com/ex/search/song.htm?gakkyokuId=283053"
      song = Dumper.extract_song(open(page).read)
      song[:title].must_equal("FIRST KISS")
      song[:artist].must_equal("あぁ!")
      song[:genre].must_equal("J-POP/グループ")
      song[:wii_number].must_equal("31864")
      song[:utaidashi].must_equal("どうして 恋人になれないの?")
    end

    VCR.use_cassette("シェラフィータ") do
      page = "http://joysound.com/ex/search/song.htm?gakkyokuId=398316"
      song = Dumper.extract_song(open(page).read)
      song[:title].must_equal("シェラフィータ")
      song[:artist].must_equal("ZABADAK")
      song[:genre].must_equal("J-POP/グループ")
      song[:wii_number].must_equal("169073")
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

  it "should take a page with links to artist pages and extract songs from all artists on this page" do
    VCR.use_cassette("z_page") do
      page = "http://joysound.com/ex/search/artistsearchindex.htm?searchType=02&searchWordType=2&charIndexKbn=02&charIndex1=36"
      res = Dumper.extract_artists_page(page)
      songs = res[:songs]
      songs.map{|song| song[:artist]}.uniq.count.must_equal(5)
    end
  end

  it "should take the first character page and extract all songs from all artists on all pages" do
    VCR.use_cassette("z_page_complete") do
      page = "http://joysound.com/ex/search/artistsearchindex.htm?searchType=02&searchWordType=2&charIndexKbn=02&charIndex1=36"
      songs = Dumper.extract_artists_pages(page)
      songs.map{|song| song[:artist]}.uniq.count.must_equal(39)
      puts songs
    end
  end
end
