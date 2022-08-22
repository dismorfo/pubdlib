# frozen_string_literal: true

require 'nice_http'
require 'json'

# Need documentation.
class Repository < Command
  @command = 'repository'
  @label = 'Commands related to content repository'
  @description = "Search entity source using it's digi_id."
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]

  def initialize
    @http = authenticate
  end  

  def action(opts)

    request = {
      path: "/api/v1/repository?digi_id=#{opts[:identifier]}"
    }
    
    resp = @http.get(request)
    raise 'Unable to search service.' unless resp.code == 200    

    data = JSON.parse(resp.data)
    puts data.to_json

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
