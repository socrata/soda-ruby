require 'test/unit'
require 'shoulda'
require 'soda/client'
require 'json'
require 'webmock/test_unit'
require 'mocha/test_unit'

# NOTE: These tests are by no means exhaustive, they're just a start
class SODATest < Test::Unit::TestCase
  DOMAIN = 'fakehost.socrata.com'
  APP_TOKEN = 'totallyfakenotrealapptoken'
  USER = 'fakeuser@socrata.com'
  PASSWORD = 'fakepassword'

  # Helpers
  def resource(name)
    File.new(File.dirname(__FILE__) + '/resources/' + name)
  end

  context 'query strings' do
    setup do
      @client = SODA::Client.new
    end

    should 'return a proper simple query string' do
      assert_equal 'foo=bar', @client.send(:query_string, :foo => 'bar')
    end

    should 'return a proper multi-param query string' do
      assert_equal 'foo=bar&quo=quux', @client.send(:query_string, :foo => 'bar',
                                                                   :quo => 'quux')
    end

    should 'escape spaces' do
      assert_equal 'foo=bar+has+spaces+in+it', @client.send(:query_string, :foo => 'bar has spaces in it')
    end

    should 'escape random symbols' do
      assert_equal 'foo=%21%40%23%24%25%5E%26%2A%28%29_%2B', @client.send(:query_string, :foo => '!@#$%^&*()_+')
    end
  end

  context 'resource paths' do
    setup do
      @client = SODA::Client.new
    end

    should 'handle a simple resource' do
      assert_equal '/resource/644b-gaut.json', @client.send(:resource_path, '644b-gaut')
    end

    should 'handle a custom resource' do
      assert_equal '/resource/visitor-records.json', @client.send(:resource_path, 'visitor-records')
    end

    should 'allow you to override content type' do
      assert_equal '/resource/visitor-records.csv', @client.send(:resource_path, 'visitor-records.csv')
    end

    # NOTE: Will be deprecated later
    should 'allow you access an old-style SODA1 path' do
      assert_equal '/api/views/644b-gaut.json', @client.send(:resource_path, '/api/views/644b-gaut')
    end

    # NOTE: Will be deprecated later
    should 'allow you access an old-style SODA1 path with output type' do
      assert_equal '/api/views/644b-gaut/rows.csv', @client.send(:resource_path, '/api/views/644b-gaut/rows.csv')
    end
  end

  # Test our response handling directly
  context 'response objects' do
    setup do
      @client = SODA::Client.new(:domain => DOMAIN, :app_token => APP_TOKEN)
    end

    should 'handle a 200 with a real JSON payload' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.json')
        .to_return(resource('earthquakes_50.response'))

      uri = URI.parse('https://fakehost.socrata.com/resource/earthquakes.json')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request.add_field('X-App-Token', 'FAKEAPPTOKEN')

      body = @client.send(:handle_response, http.request(request))
      assert_equal 50, body.size
    end

    should 'handle a 200 with an empty payload' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/empty.json')
        .to_return(resource('empty_body.response'))

      uri = URI.parse('https://fakehost.socrata.com/resource/empty.json')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request.add_field('X-App-Token', 'FAKEAPPTOKEN')

      body = @client.send(:handle_response, http.request(request))
      assert_nil body
    end

    should 'raise on a 500 error' do
      stub_request(:get, 'https://fakehost.socrata.com/kaboom.json')
        .to_return(resource('500_error.response'))

      uri = URI.parse('https://fakehost.socrata.com/kaboom.json')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request.add_field('X-App-Token', 'FAKEAPPTOKEN')

      assert_raise RuntimeError do
        @client.send(:handle_response, http.request(request))
      end
    end
  end

  # Test responses from a real fake dataset
  context 'earthquakes' do
    setup do
      SODA::Client.stubs(:generate_user_agent).returns('The Best User Agent of All Time')
      @client = SODA::Client.new(:domain => DOMAIN, :app_token => 'K6rLY8NBK0Hgm8QQybFmwIUQw')
    end

    should 'be able to access the earthquakes dataset' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.json?')
        .with(:body => 'null',
              :headers => { 'Accept' => '*/*', 'Content-Type' => 'application/json',
                            'User-Agent' => 'The Best User Agent of All Time',
                            'X-App-Token' => 'K6rLY8NBK0Hgm8QQybFmwIUQw' })
        .to_return(resource('earthquakes_50.response'))

      response = @client.get('earthquakes')
      assert_equal 50, response.size
    end

    should 'be able to perform a simple equality query' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.json?source=uw')
        .to_return(resource('earthquakes_uw.response'))

      response = @client.get('earthquakes', :source => 'uw')
      assert_equal 26, response.size
    end

    should 'be able to perform a simple $WHERE query' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.json?$where=magnitude > 5')
        .to_return(resource('earthquakes_where_gt_5.response'))

      response = @client.get('earthquakes', '$where' => 'magnitude > 5')
      assert_equal 29, response.size
    end

    should 'be able to combine a $WHERE query with a simple equality' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.json?$where=magnitude > 4&source=pr')
        .to_return(resource('earthquakes_source_pr_where_gt_4.response'))

      response = @client.get('earthquakes', '$where' => 'magnitude > 4', :source => 'pr')
      assert_equal 1, response.size
    end

    should 'get the results we expect' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.json?$where=magnitude > 4&source=pr')
        .to_return(resource('earthquakes_source_pr_where_gt_4.response'))

      response = @client.get('earthquakes', '$where' => 'magnitude > 4', :source => 'pr')
      assert_equal 1, response.size

      quake = response.first
      assert_equal 'Puerto Rico region', quake.region
      assert_equal '4.2', quake.magnitude
      assert_equal '17.00', quake.depth

      assert quake.region?
    end
  end

  context 'authenticated' do
    setup do
      SODA::Client.stubs(:generate_user_agent).returns('The Best User Agent of All Time')
      @client = SODA::Client.new(:domain => DOMAIN, :app_token => APP_TOKEN,
                                 :username => USER, :password => PASSWORD)
    end

    context 'with user accounts' do
      should 'be able to read his own email address' do
        stub_request(:get, 'https://fakeuser%40socrata.com:fakepassword@fakehost.socrata.com/api/users/current.json?')
          .to_return(resource('fakeuser.response'))

        response = @client.get('/api/users/current.json')
        assert_equal USER, response.email
      end
    end

    context 'RESTful updates' do
      should 'be able to POST a set of rows' do
        stub_request(:post, 'https://fakeuser%40socrata.com:fakepassword@fakehost.socrata.com/resource/earthquakes.json?')
          .to_return(resource('earthquakes_create_one_row.response'))

        response = @client.post('earthquakes', [{ :source => 'uw', :magnitude => 5, :earthquake_id => 42 }])
        assert_equal response['Rows Created'], 1
      end

      should 'be able to POST a form' do
        stub_request(:post, 'https://fakeuser%40socrata.com:fakepassword@fakehost.socrata.com/resource/earthquakes.json?')
          .with(:body => { 'earthquake_id' => '42', 'magnitude' => '5', 'source' => 'uw' },
                :headers => { 'Accept' => '*/*', 'Content-Type' => 'application/x-www-form-urlencoded',
                              'User-Agent' => 'The Best User Agent of All Time',
                              'X-App-Token' => 'totallyfakenotrealapptoken' })
          .to_return(resource('earthquakes_create_one_row.response'))

        response = @client.post_form('earthquakes', :source => 'uw', :magnitude => 5, :earthquake_id => 42)
        assert_equal response['Rows Created'], 1
      end
    end
  end

  context 'errors' do
    setup do
      @client = SODA::Client.new(:domain => DOMAIN, :app_token => APP_TOKEN)
    end

    should 'get an error accessing a nonexistent dataset' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/idontexist.json?')
        .to_return(resource('404.response'))

      assert_raise RuntimeError do
        @client.get('idontexist')
      end
    end
  end

  context 'raw' do
    setup do
      @client = SODA::Client.new(:domain => DOMAIN, :app_token => APP_TOKEN)
    end

    should 'be able to retrieve CSV if I so choose' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.csv?')
        .to_return(resource('earthquakes.csv.response'))

      response = @client.get('earthquakes.csv')
      assert response.is_a? String
    end

    should 'be able to retrieve CSV with a full path' do
      stub_request(:get, 'https://fakehost.socrata.com/resource/earthquakes.csv?')
        .to_return(resource('earthquakes.csv.response'))

      response = @client.get('/resource/earthquakes.csv')
      assert response.is_a? String
    end
  end
end
