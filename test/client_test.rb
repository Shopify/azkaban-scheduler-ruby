require 'test_helper'

class ClientTest < Minitest::Test
  def test_http_options
    client = AzkabanScheduler::Client.new('http://www.example.com', read_timeout: 5)

    assert_kind_of Net::HTTP, client.http
    assert_equal 5, client.http.read_timeout
  end
end
