# frozen_string_literal: true

require 'nice_http'
require 'json'
require 'erb'
require 'nokogiri'

# @todo Undocumented Class
class Se
  include ERB::Util
  @identifier = nil

  def initialize(identifier)
    @identifier = identifier
    @se = search_se_by_id(identifier)
    raise @se['error'] if @se.key?('error')

    handle.split('/')
    @se.noid = handle.split('/')[1]
  end

  def entity_alias
    aliases = {}
    aliases['book'] = 'dlts_book'
    aliases['photo'] = 'dlts_photo_set'
    aliases[type]
  end

  def type_alias
    aliases = {}
    aliases['book'] = 'books'
    aliases['photo'] = 'photos'
    aliases['image_set'] = 'photos'
    aliases[type]
  end

  def identifier
    @se.digi_id
  end

  def pdfs
    find = fmds.map { |fmd|
      next unless /pdf/.match(fmd.name)

      {
        type: 'hi',
        uri: "pdfserver://#{type_alias}/#{identifier}/#{fmd.name}",
        filesize: fmd.filesize,
        searchable: fmd.searchable
      }
    }
    find
  end

  def fmds
    @se.fmds
  end

  def search_se_by_id(identifier)
    find = search_service.get({ path: "/api/v1/repository?digi_id=#{identifier}" })
    raise "Unable to find resource #{identifier} in search service." unless find.code == 200

    JSON.parse(find.data)
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

  def collections
    # Return an empty array if isPartOf is nil or not an array
    return [] if @se.isPartOf.nil? || !@se.isPartOf.is_a?(Array)

    @se.isPartOf.map do |col|
      # Local variables for readability
      collection_name = col['name'] || 'Unknown Collection'
      collection_id   = col['uuid']
      collection_code = col['code']

      # Nested Partner data
      partner_data = col['provider'] || {}
      partner_name = partner_data['name'] || 'Unknown Partner'
      partner_id   = partner_data['uuid']
      partner_code = partner_data['code']

      {
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
      }
    end
  end

  def collection_code
    collection[0].code
  end

  def provider
    collection[0].provider
  end

  def partners
    collections.map do |col|
      p = col[:partner]
      # Ensure name exists to avoid crashes on [0, 255]
      partner_name = p[:name].to_s

      {
        title: partner_name[0, 255],
        name: partner_name,
        type: 'dlts_partner',
        language: 'und',
        identifier: p[:identifier],
        code: p[:code]
      }
    end.uniq { |h| h[:identifier] }
  end

  def handle_url
    "https://hdl.handle.net/#{handle.chomp}"
  end

  def collection_code
    # Use &. to prevent a crash if collection[0] is nil
    # Use .to_s to ensure we don't return nil to the path builder
    @se.isPartOf&.first&.code.to_s
  end

  def provider_code
    # Check the provider object safely
    # If the API returns nil for code, this returns an empty string ""
    @se.isPartOf&.first&.provider&.code.to_s
  end

  def partner_code
    # Just alias this to provider_code to keep it DRY
    provider_code
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

  def se_path
    # 1. Grab the first collection from our helper method
    # Use .first to safely handle empty arrays
    col = collections.first
    raise "No collection information found for #{@se.digi_id}" if col.nil?

    # 2. Access values using [:symbol] keys because that's how we built the helper
    partner_code    = col[:partner][:code]
    collection_code = col[:code]

    # 3. Build the root path
    root = "#{$configuration['RSBE_CONTENT']}/#{partner_code}/#{collection_code}"

    # 4. Check directories
    wip_se_path = "#{root}/wip/se/#{@se.digi_id}"
    legacy_path = "#{root}/wip/#{@se.digi_id}"

    if Dir.exist?(wip_se_path)
      wip_se_path
    elsif Dir.exist?(legacy_path)
      legacy_path
    else
      raise "Source entity directory for resource #{@se.digi_id} does not exist. Checked: #{wip_se_path}"
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

  def image_metadata(image_id)
    uri = URI("#{$configuration['IMAGE_SERVER']}/iiif/2/#{url_encode(image_id)}/info.json")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.get(uri.request_uri)
    end

    raise "Unable to fetch image metadata for #{image_id}." unless response.code == '200'

    JSON.parse(response.body)
  end

  class << self
    attr_accessor :profile, :handle, :json, :hash, :collection, :provider, :partner_code, :provider_code, :provider_code, :collection_code, :type, :noid, :entity_alias, :type_alias, :identifier, :pdfs, :fmds
  end
end
