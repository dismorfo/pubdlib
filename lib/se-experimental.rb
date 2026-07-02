# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'erb'
require 'nokogiri'

class SeExperimental
  include ERB::Util

  ENTITY_ALIASES = {
    'book' => 'dlts_book',
    'serial' => 'dlts_serial',
    'photo' => 'dlts_photo_set',
    'image_set' => 'dlts_photo_set'
  }.freeze

  TYPE_ALIASES = {
    'book' => 'books',
    'serial' => 'serials',
    'photo' => 'photos',
    'image_set' => 'photos'
  }.freeze

  def initialize(identifier, config = nil)
    @identifier = identifier
    @http = authenticated_http_session
    @config = config
    @se = search_se_by_id(identifier)
    raise @se['error'] if @se.key?('error')
  end

  def entity_alias
    ENTITY_ALIASES[type]
  end

  def type_alias
    TYPE_ALIASES[type]
  end

  def title
    @se.dig('resource', 'metadata', 'display_title')
  end

  def identifier
    @se.dig('resource', 'digi_id')
  end

  def type
    @se.dig('resource', 'do_type')
  end

  def noid
    @se.dig('resource', 'fids', 'noid')
  end

  def handle
    @se.dig('resource', 'fids', 'handle')&.chomp
  end

  def handle_url
    "https://hdl.handle.net/#{handle}"
  end

  # Returns the raw partner hash
  def partner
    @se['partner']
  end

  def partner_code
    partner&.dig('code')
  end

  def partner_name
    partner&.dig('name')
  end

  def partner_id
    partner&.dig('id')
  end

  def serial_call_number
    @se.dig('resource', 'metadata', 'call_number')
  end

  def provider
    partner
  end

  def provider_code
    partner_code
  end

  def collection
    @se['collection']
  end

  def collection_code
    collection&.dig('code')
  end

  def collection_name
    collection&.dig('name')
  end

  def collection_id
    collection&.dig('id')
  end

  def collections
    c = [{
      title: collection_name[0, 255],
      name: collection_name,
      identifier: collection_id,
      type: 'dlts_collection',
      language: 'und',
      code: collection_code,
      partner: {
        title: partner_name[0, 255],
        name: partner_name,
        type: 'dlts_partner',
        language: 'und',
        identifier: partner_id,
        code: partner_code
      }
    }]

    local_collections = @config&.extra&.collections
    # Check that it is not nil and not empty
    if !local_collections.nil? && !local_collections.empty?
      # Flatten it to unwrap the nested array structure from the CLI parser
      local_collections.flatten.each do |item|
        request = {
          path: "/api/v1/collections/#{item}"
        }
        resp = @http.get(request)
        raise 'Unable to search service.' unless resp.code == 200

        data = JSON.parse(resp.data)
        local_collection = data['response']['collection']
        c << {
          title: local_collection['title'][0, 255],
          name: local_collection['title'],
          identifier: local_collection['identifier'],
          type: 'dlts_collection',
          language: 'und',
          code: local_collection['code'],
          partner: {
            title: local_collection['partners'][0]['name'][0, 255],
            name: local_collection['partners'][0]['name'],
            type: 'dlts_partner',
            language: 'und',
            identifier: local_collection['partners'][0]['identifier'],
            code: local_collection['partners'][0]['code']
          }
        }
      end
    end

    c
  end

  def partners
    all_partners = collections.map do |col|
      p = col[:partner]
      {
        title: p[:name][0, 255],
        name: p[:name],
        type: 'dlts_partner',
        language: 'und',
        identifier: p[:identifier],
        code: p[:code]
      }
    end

    # Keep only the unique records based on the :identifier value
    all_partners.uniq { |partner| partner[:identifier] }
  end

  def fmds
    @se.dig('resource', 'fmds')
  end

  def hash
    @se.merge(
      'directory_path' => se_path,
      'profile' => profile
    )
  end

  def json
    hash.to_json
  end

  def profile
    if File.exist?("./profiles/#{partner_code}.#{collection_code}.json")
      JSON.parse(File.read("./profiles/#{partner_code}.#{collection_code}.json"))
    elsif File.exist?("./profiles/#{type}.json")
      JSON.parse(File.read("./profiles/#{type}.json")).merge(
        'id' => "#{partner_code}.#{collection_code}",
        'collection' => collection_code,
        'partner' => partner_code
      )
    else
      raise "Profile for #{identifier} not found."
    end
  end

  def image_metadata(image_id)
    uri = URI("#{$configuration['IMAGE_SERVER']}/iiif/2/#{url_encode(image_id)}/info.json")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.get(uri.request_uri)
    end

    raise "Unable to fetch image metadata for #{image_id}." unless response.code == '200'

    JSON.parse(response.body)
  end

  def se_path
    root = "#{$configuration['RSBE_CONTENT']}/#{partner_code}/#{collection_code}"
    digi_id = identifier

    if Dir.exist?("#{root}/wip/se/#{digi_id}")
      "#{root}/wip/se/#{digi_id}"
    elsif Dir.exist?("#{root}/wip/#{digi_id}")
      "#{root}/wip/#{digi_id}"
    else
      raise "Source entity directory for #{digi_id} does not exist. Expected at #{root}/wip/se/#{digi_id}"
    end
  end

  private

  def authenticated_http_session
    http = NiceHttp.new($configuration['SE_ENDPOINT'])
    resp = http.post({
      path: '/api/v0/import/user/login.json',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      data: {
        'username': $configuration['SE_USER'],
        'password': $configuration['SE_PASS']
      }
    })
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end

  def search_se_by_id(identifier)
    resp = @http.get({ path: "/api/v1/repository/search?digi_id=#{identifier}" })
    raise "Unable to find resource #{identifier} in search service." unless resp.code == 200

    JSON.parse(resp.data)
  end

end