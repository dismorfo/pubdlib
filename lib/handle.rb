# frozen_string_literal: true

require 'nice_http'

# @todo Undocumented Class
class Handle
  def bind(noid, uri)
    xml = data(uri)
    resp = request.put(path: "/id/handle/#{noid}", data: xml)

    raise "Error: Unable to reach #{$configuration['HANDLE_URL']}" unless resp.code == 200

    raise "Error registering handle #{noid}" unless resp.message == 'OK'

    puts "#{$configuration['HANDLE_REDIRECTS']}/#{noid} => #{uri}"
  end

  def request
    http = NiceHttp.new($configuration['HANDLE_URL'])
    http.headers.authorization = NiceHttpUtils.basic_authentication(
      user: $configuration['HANDLE_USER'],
      password: $configuration['HANDLE_PASS']
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
