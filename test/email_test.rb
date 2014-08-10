ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require './email'

class EmailTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_displays_forms
    get '/email'
    assert last_response.ok?
    assert last_response.body.include?('<h2>Email Request</h2>')
    assert last_response.body.include?("To")
    assert last_response.body.include?("Receiver's Name")
    assert last_response.body.include?("From")
    assert last_response.body.include?("Sender's Name")
    assert last_response.body.include?("Subject")
    assert last_response.body.include?("Body")
  end

  def test_successful_email_sending
    params = {
      to: "to@test.com",
      to_name: "To",
      from: "from@test.com",
      from_name: "From",
      subject: "subject",
      body: "<h2>Hi</h2>",
      cc: "cc@test.com",
      cc_name: "To Cc"
    }

    self.stub :send_mailgun, {} do
    end

    post '/email', params
    assert last_response.ok?
    assert last_response.body.include?("Email successfully sent to to@test.com, cc@test.com.")
  end
end
