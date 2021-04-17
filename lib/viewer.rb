# frozen_string_literal: true

require 'dotenv/load'
require 'nice_http'
require 'json'

# rubocop:disable Metrics/MethodLength

# Username for Repository search endpoint
Dotenv.require_keys('SE_USER')
# Password for Repository search endpoint
Dotenv.require_keys('SE_PASS')
# Repository search endpoint.
Dotenv.require_keys('SE_ENDPOINT')

# @todo Undocumented Class
class Viewer
  def initialize
    @http = authenticate
  end

  def post(object)
    request = @http.post(
      path: '/api/v1/objects',
      headers: {
        'Content-Type': 'application/json'
      },
      data: object
    )
    res = JSON.parse(request.data)
    raise res.error if res.key?('error')

    puts res.data.to_json
  end

  def authenticate
    # http = NiceHttp.new(ENV['SE_ENDPOINT'])
    http = NiceHttp.new('http://localhost:9000')
    request = {
      path: '/api/v0/import/user/login.json',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        'username': ENV['SE_USER'],
        'password': ENV['SE_PASS']
      }
    }
    resp = http.post(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end
end

# rubocop:enable Metrics/MethodLength
