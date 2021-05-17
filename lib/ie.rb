# frozen_string_literal: true

require 'rubygems'
require 'nokogiri'
require 'json'
require 'erb'
require 'saxerator'
require 'optparse'
require 'yaml'
require 'pp'
require 'uri'
require './lib/mods.rb'
require './lib/se.rb'
require './lib/book.rb'

# @todo Undocumented Class
class IE
  include ERB::Util
  def initialize(ieuu, providers)
    @ses = []
    @collections = []
    @partners = []
    providers.split(',').each do |item|
      if item.include? ':'
        cp = item.split(':')
        collection = collection_metadata(cp[0], cp[1])
        @collections.push(collection)
        @partners.push(collection.partner)
      else
        @partners.push(partner_metadata(item))
      end
    end

    abort "Intellectual entity #{ieuu} must have at least one collection that belongs to a partner, none found." unless @collections.size.positive?

    @mets = mets ieuu
    @ieuu = @mets.xpath('//mets/@OBJID').first.value
    @marc = ie_marc
    @mods = ie_mods
    @entities = ie_entities

    @entities.each do |se|
      next if se.nil?

      entity = {
        ieuu: @ieuu,
        collections: @collections,
        partners: @partners,
        order: se.attributes['ORDER'].value,
        is_multivol: false
      }

      entity.orderlabel = if se.attributes['ORDERLABEL'].nil?
                            entity.orderlabel = nil
                          else
                            entity.orderlabel = se.attributes['ORDERLABEL'].value
                          end

      se.xpath('mptr').each do |mptr|
        entity.identifier = mptr.attributes['href'].value.split('/')[4]
      end
      @ses.push(entity)
    end

    # Book can be multivolume even if @ses count = 1
    if is_multivol
      @ses.each_with_index do |_se, index|
        @ses[index].is_multivol = true
      end
    end

  end

  def is_multivol
    is_multivol = false
    # Check if book is part of a multivol.
    if @ses.count > 1
      is_multivol = true
    # A book can be part of a multivol, but we only have 1 of the volumes.
    # @todo: I think this is what we are saying with this check.
    elsif !@ses[0].orderlabel.nil?
      is_multivol = true
    end
    is_multivol
  end

  def image_metadata(image_id)
    http = NiceHttp.new($configuration['IMAGE_SERVER'])
    request = {
      path: "/iiif/2/#{url_encode(image_id)}/info.json"
    }
    resp = http.get(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    JSON.parse(resp.data)
  end

  def se_endpoint
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

  def collection_metadata(partner, collection)
    resp = se_endpoint.get(path: "/api/v1/repository/partners/#{partner}/#{collection}")
    raise 'Collection not found.' unless resp.code == 200

    data = JSON.parse(resp.data)

    {
      title: data.collection.name[0..254],
      type: 'dlts_collection',
      language: 'und',
      identifier: data.collection.id,
      code: data.collection.code,
      name: data.collection.name,
      partner: {
        title: data.name[0..254],
        type: 'dlts_partner',
        language: 'und',
        identifier: data.id,
        code: data.code,
        name: data.name
      }
    }
  end

  def partner_metadata(partner)
    resp = se_endpoint.get(path: "/api/v1/repository/partners/#{partner}")
    raise 'Partner not found.' unless resp.code == 200

    data = JSON.parse(resp.data)
    {
      title: data.name[0..254],
      type: 'dlts_partner',
      language: 'und',
      identifier: data.id,
      code: data.code,
      name: data.name
    }
  end

  def ie_path(ieuu)
    path = "#{$configuration['RSBE_CONTENT']}/#{@collections[0].partner.code}/#{@collections[0].code}/wip/ie/#{ieuu}"
    abort("Path to intellectual entity #{path} does not exist.") unless Dir.exist?(path)

    path
  end

  def ie_mets(ieuu)
    ieuu_path = ie_path ieuu
    path = "#{ieuu_path}/data/#{ieuu}_mets.xml"
    abort("METS file for intellectual entity #{ieuu} not found.") unless File.exist?(path)

    path
  end

  def ie_mods
    path = "#{ie_path(@mets.xpath('//mets/@OBJID').first.value)}/data/#{@mets.xpath('//mdRef[@MDTYPE="MODS"]/@href').first.value}"
    abort("MODS file for intellectual entity #{@ieuu} not found.") unless File.exist?(path)

    Nokogiri::XML.parse(File.open(path)).remove_namespaces!
  end

  def ie_entities
    @mets.xpath('//mets/structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]')
  end

  def ie_marc
    path = "#{ie_path(@mets.xpath('//mets/@OBJID').first.value)}/data/#{@mets.xpath('//mdRef[@OTHERMDTYPE="MARCXML"]/@href').first.value}"
    abort("Marc file for intellectual entity #{@path} not found.") unless File.exist?(path)

    Nokogiri::XML.parse(File.open(path)).remove_namespaces!
  end

  def ie_metsrights
    path = "#{ie_path}/data/#{@ieuu}_mets.xml"
    abort("METS file for intellectual entity #{@ieuu} not found.") unless File.exist?(path)

    path
  end

  def mets(ieuu)
    mets_path = ie_mets ieuu
    Nokogiri::XML.parse(File.open(mets_path)).remove_namespaces!
  end

  def hash
    # items = []
    # viewer = Viewer.new
    @ses.each do |entity|
      # Load SE
      se = Se.new(entity.identifier)
      if se.type == 'book'
        book = Book.new(entity, se)
        book.hash.each do |item|
          filepath = "#{$configuration['CONTENT_REPOSITORY_PATH']}/#{se.type_alias}/#{entity.ieuu}.#{entity.identifier}.#{item.entity_language}.json"
          temp_write_json = File.open(filepath, 'w')
          temp_write_json.write(item.to_json)
          temp_write_json.close
          puts "Entity #{se.identifier} saved as #{filepath}"
        end
      end
      # viewer.post(items.first.to_json)
    end
  end
end
