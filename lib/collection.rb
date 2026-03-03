# frozen_string_literal: true

require 'uri'
require 'nice_http'
require 'json'
require 'erb'
require './lib/mods.rb'

# @todo Undocumented Class
class Collection
  include ERB::Util
  def initialize(identifier)

    raw_identifier = if File.exist?(identifier)
                   File.read(identifier).strip
                 else
                   identifier
                 end

    # 2. Extract the ID if it happens to be a URL
    if raw_identifier =~ /\Ahttps?:\/\//
      final_id = URI.parse(raw_identifier).path.split('/').last
    else
      final_id = raw_identifier
    end
    @identifier = final_id
  end


  def json
    hash.to_json
  end

  def hash
    self.collection
  end

  def collection
    collection = search_collection_by_id(@identifier)
  end

  def code
    self.collection['code']
  end

  def partner
    self.collection
  end

  def search_collection_by_id(identifier)
    find = search_service.get({ path: "/api/v1/repository/collections/#{identifier}" })
    raise "Unable to find collections #{identifier} in search service." unless find.code == 200

    JSON.parse(find.data)
  end

  def search_service
    http = NiceHttp.new($configuration['SE_ENDPOINT'])
    request = {
      path: '/api/v0/import/user/login.json',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        'username': $configuration['SE_USER'],
        'password': $configuration['SE_PASS']
      }
    }
    resp = http.post(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end

end
