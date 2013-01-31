require 'test/unit'
require 'shoulda'
require 'soda/client'

# NOTE: These tests are by no means exhaustive, they're just a start

class SODATest < Test::Unit::TestCase
  context "earthquakes" do
    setup do
      @client = SODA::Client.new({:domain => "sandbox.demo.socrata.com", :app_token => "K6rLY8NBK0Hgm8QQybFmwIUQw" })
    end

    should "be able to access the earthquakes dataset" do
      response = @client.get("earthquakes")
      assert_equal 1000, response.size
    end

    should "be able to perform a simple equality query" do
      response = @client.get("earthquakes", {:source => "uw"})
      assert_equal 26, response.size
    end

    should "be able to perform a simple $WHERE query" do
      response = @client.get("earthquakes", {"$where" => "magnitude > 5"})
      assert_equal 29, response.size
    end

    should "be able to combine a $WHERE query with a simple equality" do
      response = @client.get("earthquakes", {"$where" => "magnitude > 4", :source => "pr"})
      assert_equal 1, response.size
    end

    should "get the results we expect" do
      response = @client.get("earthquakes", {"$where" => "magnitude > 4", :source => "pr"})
      assert_equal 1, response.size

      quake = response.first
      assert_equal "Puerto Rico region", quake.region
      assert_equal "4.2", quake.magnitude
      assert_equal "17.00", quake.depth

      assert quake.region?
    end
  end

  context "authenticated" do 
    setup do
      @client = SODA::Client.new({
        :domain => "sandbox.demo.socrata.com", :app_token => "K6rLY8NBK0Hgm8QQybFmwIUQw", 
        :username => "sandbox-user@socrata.com", :password => "V3mANe{7JMsc(G6P"})
    end

    should "be able to read his own email address" do
      response = @client.get("/api/users/current")
      assert_equal "sandbox-user@socrata.com", response.email
    end

    should "be able to update metadata on a dataset" do
      response = @client.get("/api/views/s8cq-fqry")

      new_description = "Test run at #{Time.new}"
      response = @client.put("/api/views/s8cq-fqry", {:description => new_description })

      assert_equal new_description, response.description
    end
  end

  context "errors" do
    setup do
      @client = SODA::Client.new({:domain => "sandbox.demo.socrata.com", :app_token => "K6rLY8NBK0Hgm8QQybFmwIUQw" })
    end

    should "get an error accessing a nonexistent dataset" do
      assert_raise RuntimeError do
        @client.get("idontexist")
      end
    end
  end

  context "a non-existent domain" do
    setup do
      @client = SODA::Client.new({:domain => "fakedomain.demo.socrata.com", :app_token => "K6rLY8NBK0Hgm8QQybFmwIUQw" })
    end

    should "be able to access the earthquakes dataset" do
      assert_raise RuntimeError do
        @client.get("earthquakes")
      end
    end
  end

  context "raw" do
    setup do
      @client = SODA::Client.new({:domain => "sandbox.demo.socrata.com", :app_token => "K6rLY8NBK0Hgm8QQybFmwIUQw" })
    end

    should "be able to retrieve CSV if I so choose" do
      response = @client.get("earthquakes.csv")
      assert response.is_a? String
    end

    should "be able to retrieve CSV with a full path" do
      response = @client.get("/resource/earthquakes.csv")
      assert response.is_a? String
    end
  end
end
