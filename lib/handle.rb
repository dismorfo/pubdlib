# frozen_string_literal: true

require 'dotenv/load'
require 'nice_http'

# Handle server.
Dotenv.require_keys('HANDLE_URL')
# Handle user.
Dotenv.require_keys('HANDLE_USER')
# Handle pass.
Dotenv.require_keys('HANDLE_PASS')

# @todo Undocumented Class
class Handle
  def bind(noid, uri)
    xml = data(uri)
    resp = request.put(path: "/id/handle/#{noid}", data: xml)

    raise "Error: Unable to reach #{ENV['HANDLE_URL']}" unless resp.code == 200

    raise "Error registering handle #{noid}" unless resp.message == 'OK'

    puts "#{noid} linked to #{uri}"
  end

  def request
    http = NiceHttp.new(ENV['HANDLE_URL'])
    http.headers.authorization = NiceHttpUtils.basic_authentication(
      user: ENV['HANDLE_USER'],
      password: ENV['HANDLE_PASS']
    )
    http.headers['content-type'] = 'application/xml'
    http
  end

  def data(uri)
    %(<?xml version="1.0" encoding="UTF-8"?>
      <hs:info xmlns:hs="info:nyu/dl/v1.0/identifiers/handle">
          <hs:binding>#{uri}</hs:binding>
          <hs:description></hs:description>
      </hs:info>)
  end
end
