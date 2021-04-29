# frozen_string_literal: true

require 'dotenv/load'
require 'nice_http'
require 'json'

# rubocop:disable Metrics/MethodLength

# @todo Undocumented Class
class Media
  def initialize
    @http = authenticate
  end

  def post(object)
    request = @http.post(
      path: '/api/v0/objects',
      headers: {
        'Content-Type': 'application/json'
      },
      data: object
    )
    res = JSON.parse(request.data)
    raise res.error if res.key?('error')

    res
  end

  def authenticate
    http = NiceHttp.new(ENV['MEDIA_ENDPOINT'])
    request = {
      path: '/api/v0/import/user/login.json',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        'username': ENV['MEDIA_USER'],
        'password': ENV['MEDIA_PASS']
      }
    }
    resp = http.post(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end
end

# rubocop:enable Metrics/MethodLength
