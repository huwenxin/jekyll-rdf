require 'jekyll'
require 'test-unit'
require 'shoulda-context'
require 'rspec/expectations'
require 'pry'

class TestJekyllRdf < Test::Unit::TestCase
  include RSpec::Matchers

  SOURCE_DIR = File.join(File.dirname(__FILE__), "source")
  DEST_DIR   = File.join(SOURCE_DIR, "_site")

  TEST_OPTIONS = {
    'source'         => SOURCE_DIR,
    'destination'    => DEST_DIR,
    'jekyll_rdf'     => {
      'path' => "#{SOURCE_DIR}/rdf-data/simpsons.ttl"
    }
  }
  config = Jekyll.configuration(TEST_OPTIONS)
  site = Jekyll::Site.new(config)
  site.process
  pagearray = site.pages.select{|p| p.name == "http://www.ifi.uio.no/INF3580/simpsons#Homer.html"} # creates an array
  homer_page = pagearray[0] # select first entry of selection
  
  context "Generating a site with RDF data" do    
    should "create a file which mentions 'Lisa Simpson'" do
      s = File.read("#{DEST_DIR}/rdfsites/http:/www.ifi.uio.no/INF3580/simpsons#Lisa.html") # read static file
      expect(s).to include 'Lisa Simpson'
    end
  end

  context "Generate a page from RDF data" do
    should "have rdf data" do
      assert_not_nil(homer_page.data['rdf'])
    end
    should "contain correct age of Homer Simpson" do
        assert homer_page.data['rdf'].include?(['http://www.ifi.uio.no/INF3580/simpsons#Homer','http://xmlns.com/foaf/0.1/age','36'])
    end
  end

end
#test