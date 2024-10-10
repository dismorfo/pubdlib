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
    root = "#{$configuration['RSBE_CONTENT']}/#{collection[0].provider.code}/#{collection[0].code}"
    # Current location.
    if Dir.exist?("#{root}/wip/se/#{@se.digi_id}")
      "#{root}/wip/se/#{@se.digi_id}"

    # Legacy location.
    elsif Dir.exist?("#{root}/wip/#{@se.digi_id}")
      "#{root}/wip/#{@se.digi_id}"
    else
      raise "Source entity directory for resource #{@se.digi_id} does not exist."
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

  class << self
    attr_accessor :profile, :handle, :json, :hash, :collection, :provider, :provider_code, :collection_code, :type, :noid, :entity_alias, :type_alias, :identifier, :pdfs, :fmds
  end
end
