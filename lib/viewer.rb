# frozen_string_literal: true

require 'nice_http'
require 'json'

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

    res.data
  end

  def delete(object)
    identifier = object.hash.identifier
    path = "/api/objects/resource/#{identifier}"
    request = @http.delete(
      path: path,
      headers: {
        'Content-Type': 'application/json'
      },
    )
    res = JSON.parse(request.data)
    raise res.error if res.key?('error')

    res
  end

  def authenticate
    http = NiceHttp.new($configuration['VIEWER_ENDPOINT'])
    request = {
      path: '/api/v0/import/user/login.json',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        'username': $configuration['VIEWER_USER'],
        'password': $configuration['VIEWER_PASS']
      }
    }
    resp = http.post(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end
end
