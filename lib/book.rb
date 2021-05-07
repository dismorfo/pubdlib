#!/usr/bin/env ruby

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
require_relative '../lib/mods.rb'
require_relative '../lib/se.rb'
require_relative '../lib/viewer.rb'
include ERB::Util

# @TODO Needs documentation.
module DltsPublisher
  def self.image_metadata(image_id)
    http = NiceHttp.new(ENV['IMAGE_SERVER'])
    request = {
      path: "/iiif/2/#{url_encode(image_id)}/info.json"
    }
    resp = http.get(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    JSON.parse(resp.data)
  end

  def self.se_endpoint
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

  def self.collection_metadata(partner, collection)
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

  def self.partner_metadata(partner)
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

  abort('You must provide collection_path, script(Latin, Arabic, etc), local repository path') unless ARGV.size > 2

  options = {}

  @collections = []

  @partners = []

  @ieuu = nil

  ses = []

  @need_category = false

  @marc_file_mapping = nil

  @marc_file_path = nil

  @providers = nil

  @partof = []

  @script = 'Latn'

  # bundle exec ruby ./lib/dlts_publisher.rb /Users/ortiz/tools/rstar/content/princeton/aco -s Latn -f 959b583c-59ca-4282-b74d-ee9f32d15458 -k true | jq .

  OptionParser.new do |opts|
    opts.banner = 'Usage: example.rb [options]'
    opts.on('-i', '--ieuu Intellectual Entity', 'IE unique identifier') { |v| @ieuu = v.strip }
    opts.on('-s', '--script Writing systems', 'Writing systems, e.g., Latn or Arab') { |v| @script = v }
    opts.on('-p', '--providers Providers', 'Providers') { |v| @providers = v }
    opts.on('-k', '--category Need Category', 'Need Category') { @need_category = true }
    opts.on('-m', '--marc MARC file with Call Numbers', 'MARC file with call numbers') { |v| options[:marc_file] = v }
  end.parse!

  abort 'Flag IE unique identifier is required.' if @ieuu.nil?

  abort('Flag providers is required.') if @providers.nil?

  @providers.split(',').each do |item|
    if item.include? ':'
      cp = item.split(':')
      collection = collection_metadata(cp[0], cp[1])
      @collections.push(collection)
      @partners.push(collection.partner)
    else
      @partners.push(partner_metadata(item))
    end
  end

  abort "Intellectual entity #{@ieuu} must have at least one collection that belongs to a partner, none found." unless @collections.size.positive?

  ie_path = "#{ENV['RS_CONTENT']}/#{@collections[0].partner.code}/#{@collections[0].code}/wip/ie/#{@ieuu}"

  abort("Path to intellectual entity #{ie_path} does not exist.") unless Dir.exist?(ie_path)

  ie_mets = "#{ie_path}/data/#{@ieuu}_mets.xml"

  abort("METS file for intellectual entity #{@ieuu} not found.") unless File.exist?(ie_mets)

  # @todo Try to figure out what are we doing here.
  if options[:marc_file] != nil
    @marc_file_mapping = options[:marc_file].split(',')[0]
    @marc_file_path = options[:marc_file].split(',')[1]
    abort("The file with mapping #{@marc_file_mapping} doesn't exist") unless File.exist?(@marc_file_mapping)
    abort("The directory with MARC files #{@marc_file_path} doesn't exist") unless File.exist?(@marc_file_path)
  end

  parser = Saxerator.parser(File.new(ie_mets))

  @id = parser.for_tag(:mets).first.attributes['OBJID']

  # Collect digi_id's and check for multivolume.
  parser.for_tag(:div).with_attributes(TYPE: 'INTELLECTUAL_ENTITY').each do |se|
    next if se.nil?

    ses.push(
      [
        se['mptr'].attributes['xlink:href'].split('/')[4],
        se.attributes['ORDERLABEL'],
        se.attributes['ORDER']
      ]
    )
  end

  # Check if book is part of a multivol.
  if ses.size > 1
    is_multivol = true
  # A book can be part of a multivol, but we only have 1 of the volumes.
  # @todo: I think this is what we are saying with this check.
  elsif !ses[0][1].nil?
    is_multivol = true
  else
    is_multivol = false
  end

  ses.each do |entity|
    se = Se.new(entity[0])

    @handle = se.handle

    mets_file = "#{se.hash.directory_path}/data/#{se.identifier}_mets.xml"

    abort("The file #{mets_file} for the book #{se.identifier} doesn't exist") unless File.exist?(mets_file)

    @doc = Nokogiri::XML.parse(File.open(mets_file)).remove_namespaces!

    @mets_parser = Saxerator.parser(File.new(mets_file))

    mods_file_name = @doc.xpath('//mdRef[@MDTYPE="MODS"]/@href').to_s

    @rights_file_name = @doc.xpath('//mdRef[@MDTYPE="METSRIGHTS"]/@href').to_s

    @rights_file = "#{se.hash.directory_path}/data/#{@rights_file_name}"

    abort("The file #{@rights_file} for the book #{se.identifier} doesn't exist") unless File.exist?(@rights_file)

    @rights_doc_xml = Nokogiri::XML.parse(File.open(@rights_file)).remove_namespaces!

    @rights = @rights_doc_xml.xpath('//RightsDeclaration/text()').to_s

    @scan_data = @doc.xpath('//structMap/@TYPE').to_s

    @orientation = @scan_data.split(' ')[1].split(':')[1] =~ /^horizontal$/i ? 1 : 0

    @read_order = @scan_data.split(' ')[2].split(':')[1] =~ /^right(2|_to_)left$/i ? 1 : 0

    @scan_order = @scan_data.split(' ')[3].split(':')[1] =~ /^right(2|_to_)left$/i ? 1 : 0

    @page_count = @doc.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').size

    @rep_image_div = @doc.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').first

    label = @rep_image_div.xpath('@ID').to_s.gsub('s-', '')

    rep_image_metadata = image_metadata "#{se.type_alias}/#{se.identifier}/#{label}_d.jp2"

    rep_image = {
      isPartOf: se.identifier,
      sequence: [1],
      realPageNumber: 1,
      cm: {
        uri: "fileserver://#{se.type_alias}/#{se.identifier}/#{label}_d.jp2",
        width: rep_image_metadata.width,
        height: rep_image_metadata.height,
        levels: '',
        dwtLevels: '',
        compositingLayerCount: '',
        timestamp: Time.now.to_i.to_s
      }
    }

    mods = Mods.new(
      identifier: se.identifier,
      ieuu: @id,
      script: @script,
      is_multivol: is_multivol,
      need_category: @need_category,
      xml: "#{se.hash.directory_path}/data/#{mods_file_name}"
    )

    # puts @marc_file_mapping
    # puts @marc_file_path

    items = []

    viewer = Viewer.new

    if se.type == 'book'
      items.push(
        entity_title: mods.title[0..254],
        identifier: se.identifier,
        entity_language: mods.entity_language,
        entity_status: '1',
        entity_type: se.entity_alias,
        ieuu: @id,
        noid: se.handle,
        metadata: {
          title: {
            label: 'Title',
            value: [
              mods.title
            ]
          },
          subtitle: {
            label: 'Subtitle',
            value: [
              mods.subtitle
            ]
          },
          author: {
            label: 'Author/Contributor',
            value: mods.authors
          },
          publisher: {
            label: 'Publisher',
            value: [mods.publisher]
          },
          publication_location: {
            label: 'Place of Publication',
            value: [mods.publication_location]
          },
          publication_date_text: {
            label: 'Date of Publication',
            value: [mods.pub_date_string]
          },
          publication_date: {
            label: 'Date of Publication',
            value: [mods.pub_date]
          },
          topic: {
            label: 'Topic',
            value: [],
            # value: mods.get_topic(
            #   need_category,
            #   @marc_file_mapping,
            #   @marc_file_path,
            #   se.identifier
            # )
          },
          collection: {
            label: 'Collection',
            value: @collections
          },
          partner: {
            label: 'Partner',
            value: @partners
          },
          handle: {
            label: 'Permanent Link',
            value: ["http://hdl.handle.net/#{se.handle}"]
          },
          read_order: {
            label: 'Read Order',
            value: [@read_order]
          },
          scan_order: {
            label: 'Scan Order',
            value: [@scan_order]
          },
          binding_orientation: {
            label: 'Binding Orientation',
            value: [@orientation]
          },
          page_count: {
            label: 'Read Order',
            value: [@page_count]
          },
          sequence_count: {
            label: 'Read Order',
            value: [@page_count]
          },
          call_number: {
            label: 'Call Number',
            value: [
              # mods.call_number(@marc_file_mapping, @marc_file_path, se.identifier)
            ]
          },
          identifier: {
            label: 'Identifier',
            value: [se.identifier]
          },
          language: {
            label: 'Language',
            value: [mods.language]
          },
          language_code: {
            label: 'Language',
            value: [mods.language_code]
          },
          pdfs: {
            label: 'PDF',
            value: se.pdfs
          },
          representative_image: rep_image,
          rights: {
            label: 'Rights',
            value: [@rights]
          },
          subject: {
            label: 'Subject',
            value: mods.subject
          }
        },
        multivolume: {
          volume: mods.multivolume(ses[2], ses[1], @collections)
        },
        # series: mods.series(@collections, @partners)
      )
    end
    # viewer.post(items.first.to_json)
    puts items.first.to_json
  end
end
