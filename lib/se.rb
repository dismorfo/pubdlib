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
# RSBE content.
Dotenv.require_keys('RSBE_CONTENT')

# @todo Undocumented Class
class Se
  def initialize(identifier)
    datasource = search_se_by_id(identifier)
    raise datasource['error'] if datasource.key?('error')

    @se = datasource
  end

  def search_se_by_id(identifier)
    find = search_service.get(
      path: "/api/v1/repository?digi_id=#{identifier}"
    )
    raise 'Unable to find resource in search service.' unless find.code == 200

    @se = JSON.parse(find.data)

    @se
  end

  def noid
    @se.noid
  end

  def type
    @se.type
  end

  def collection
    @se.isPartOf
  end

  def collection_code
    collection[0].code
  end

  def provider
    collection[0].provider
  end

  def provider_code
    collection[0].provider.code
  end

  def hash
    @se.merge(
      directory_path: se_path,
      profile: profile,
      handle: handle.chomp
    )
  end

  def json
    hash.to_json
  end

  def search_service
    http = NiceHttp.new(ENV['SE_ENDPOINT'])
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

  def se_path
    root = "#{ENV['RSBE_CONTENT']}/#{collection[0].provider.code}/#{collection[0].code}"
    # Current location.
    if Dir.exist?("#{root}/wip/se/#{@se.digi_id}")
      "#{root}/wip/se/#{@se.digi_id}"

    # legacy location
    elsif Dir.exist?("#{root}/wip/#{@se.digi_id}")
      "#{root}/wip/#{@se.digi_id}"
    else
      raise 'Source entity directory does not exist.'
    end
  end

  def read_resource(filepath)
    raise "File does not exist #{filepath}." unless File.exist?(filepath)

    File.read(filepath).strip
  end

  def handle
    read_resource("#{se_path}/handle")
  end

  def profile
    if File.exist?("./profiles/#{collection[0].provider.code}.#{collection[0].code}.json")
      data = JSON.parse(File.read("./profiles/#{collection[0].provider.code}.#{collection[0].code}.json"))
    elsif File.exist?("./profiles/#{type}.json")
      data = JSON.parse(File.read("./profiles/#{type}.json"))
      data['id'] = "#{collection[0].provider.code}.#{collection[0].code}"
      data['collection'] = collection[0].code
      data['partner'] = collection[0].provider.code
    else
      raise "Profile for #{@se.digi_id} not found."
    end
    data
  end
end

# rubocop:enable Metrics/MethodLength
