# frozen_string_literal: true

require 'nice_http'
require 'json'

# @todo Undocumented Class
class Media
  def post(object)
    @http = authenticate
    request = @http.post(
      path: '/api/v0/objects',
      headers: {
        'Content-Type': 'application/json'
      },
      data: object
    )
    res = JSON.parse(request.data)
    raise res.error if res.key?('error')

    @http.get('/user/logout')

    res
  end

  def authenticate
    http = NiceHttp.new($configuration['MEDIA_ENDPOINT'])
    request = {
      path: '/api/v0/import/user/login.json',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        'username': $configuration['MEDIA_USER'],
        'password': $configuration['MEDIA_PASS']
      }
    }
    resp = http.post(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end
end
