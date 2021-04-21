#!/usr/bin/env ruby

# frozen_string_literal: true

require 'rubygems'
require 'nokogiri'
require 'nice_http'
require 'json'
# require 'saxerator'
require 'dotenv/load'
require 'erb'


# require_relative '../lib/book.rb'
# require_relative '../lib/metadata_json.rb'
# require_relative '../lib/drupal_json.rb'

# rubocop:disable Layout/LineLength
# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/BlockLength

# @TODO Needs documentation.
class Book
  def initialize(source_entity)
    @se = source_entity

    # abort('You must provide collection_path, script(Latin, Arabic, etc), local repository path') unless ARGV.size > 2

    # collections = []

    # partners = []

    # collection_ids = []

    # options = {}

    # script = ARGV[1]

    # collection_path = ARGV[0]

    # collection_file_path = "#{collection_path}/collection_url"

    # need_category = false

    # marc_file_mapping = nil

    # marc_file_path = nil
  end

  def hash
    # ie_file_path = "#{se[:directory_path]}collection_path}/wip/ie/#{ie_code}/data/#{ie_code}_mets.xml"

    # abort("The file #{ie_file_path} doesn't exist") unless File.exist?(ie_file_path)



    @se[:directory_path]
  end

  def json
    hash.to_json
  end


  # OptionParser.new do |opts|
  #   opts.banner = 'Usage: example.rb [options]'
  #   opts.on('-f', '--ie_file File', 'IE File') { |v| options[:ie_file] = v }

  #   opts.on('-c', '--collection_id Collection Id', 'Collection id') { |v| options[:collection_id] = v }
  #   opts.on('-p', '--partner_id Partner Id', 'Partner id') { |v| options[:partner_id] = v }
  #   opts.on('-t', '--type Item Type', 'Item Type') { |v| options[:type] = v }

  #   opts.on('-k', '--category Need Category', 'Need Category') { options[:need_category] = true }
  #   opts.on('-m', '--marc MARC file with Call Numbers', 'MARC file with call numbers') { |v| options[:marc_file] = v }
  # end.parse!

  # need_category = true unless options[:need_category].nil?



  # collection_ids << "https://rsbe.dlib.nyu.edu/api/v0/colls/#{options[:collection_id]}" unless options[:collection_id].nil?

  # abort("The collection #{collection_path} does not exist.") unless Dir.exist?(collection_path)

  # abort("The file #{collection_file_path} for the collection #{collection_path} does not exist.") unless File.exist?(collection_file_path)

  # collection_ids << File.open(collection_file_path).readline

  # collection_ids.each do |collection_url|
  #   # Get collection information using collection_url file inside collection_path directory
  #   collection_conn = Faraday.new(url: collection_url)
  #   collection_conn.basic_auth(ENV['RSBE_USER'], ENV['RSBE_PASS'])
  #   # check status code
  #   collection = JSON.parse(collection_conn.get.body).to_hash
  #   # Get partner information using collection
  #   partner_conn = Faraday.new(url: collection['partner_url'])
  #   partner_conn.basic_auth(ENV['RSBE_USER'], ENV['RSBE_PASS'])
  #   collection[:partner] = JSON.parse(partner_conn.get.body).to_hash
  #   partners.push(collection[:partner])
  #   # Add it to the collection []
  #   collections.push(collection)
  # end

  # if !options[:partner_id].nil?
  #   # check status code
  #   partner_url = "https://rsbe.dlib.nyu.edu/api/v0/partners/#{options[:partner_id]}"
  #   # Get partner information using collection
  #   partner_conn = Faraday.new(url: partner_url)
  #   partner_conn.basic_auth(ENV['RSBE_USER'], ENV['RSBE_PASS'])
  #   partner_response = partner_conn.get
  #   if partner_response.status == 200
  #     partners << JSON.parse(partner_response.body).to_hash
  #   else
  #     abort("Additional partner requested with the use of flag -p, but partner was not found. See #{partner_url}}")
  #   end
  # end

  # marc_file_mapping = nil
  # if options[:marc_file] != nil
  #   marc_file_mapping = options[:marc_file].split(',')[0]
  #   marc_file_path = options[:marc_file].split(',')[1]
  #   abort("The file with mapping #{marc_file_mapping} doesn't exist") unless File.exist?(marc_file_mapping)
  #   abort("The directory with MARC files #{marc_file_path} doesn't exist") unless File.exist?(marc_file_path)
  # end

  # parser = Saxerator.parser(File.new(ie_file_path))

  # items = []

  # ies = parser.for_tag(:div).with_attributes(TYPE: 'INTELLECTUAL_ENTITY')

  # # Find all the resources that are associated with this intellectual entity
  # ies.each do |ie|
  #   if !ie.nil?
  #     identifier = ie['mptr'].attributes['xlink:href'].split('/')[4]
  #     se_url = File.open("#{collection_path}/wip/se/#{identifier}/se_url").readline
  #     # Handle file inside SE directory includes minted handle.
  #     handle_file = "#{collection_path}/wip/se/#{identifier}/handle"
  #     # Abort if handle file does not exist.
  #     abort("The file #{handle_file} for the resource with id #{identifier} doesn't exist") unless File.exist?(handle_file)
  #     handle = File.open(handle_file).readline.strip
  #     # Get collection information using collection_url file inside collection_path directory
  #     se_conn = Faraday.new(url: se_url)
  #     se_conn.basic_auth(ENV['RSBE_USER'], ENV['RSBE_PASS'])
  #     se_response = JSON.parse(se_conn.get.body).to_hash
  #     # Get fmds information
  #     fmds_conn = Faraday.new(url: se_response['fmds_url'])
  #     fmds_conn.basic_auth(ENV['RSBE_USER'], ENV['RSBE_PASS'])
  #     fmds_response = fmds_conn.get
  #     fmds = JSON.parse(fmds_response.body) unless fmds_response.status != 200
  #     mets_file = "#{collection_path}/wip/se/#{identifier}/data/#{identifier}_mets.xml"
  #     abort("The file #{mets_file} for the resource with id #{identifier} doesn't exist") unless File.exist?(mets_file)
  #     items.push(
  #       identifier: identifier,
  #       script: script,
  #       need_category: need_category,
  #       type: se_response['do_type'].to_s,
  #       noid: handle.gsub('2333.1/', ''),
  #       handle: handle,
  #       multi_volume: ies.count > 1,
  #       volume: ie.attributes['ORDERLABEL'],
  #       volume_order: ie.attributes['ORDER'],
  #       collections: collections,
  #       collection_path: collection_path,
  #       partners: partners,
  #       fmds: fmds,
  #       mets: mets_file,
  #       marc_file_mapping: marc_file_mapping,
  #       marc_file_path: marc_file_path
  #     )
  #   end
  # end

  # # @todo Not sure why the else if here. Ask Kate.
  # # if items.size > 1
  # #   multi_volume = true
  # # elsif !items[0][1].nil?
  # #   multi_volume = true
  # # end

  # res = []

  # items.each do |item|
  #   if item[:type] == 'book'
  #     res.push(book_to_json(item))
  #   elsif item[:type] == 'map'
  #     res.push(map_to_json(item))
  #   else
  #     abort("Type #{item[:type]} not supported")
  #   end
  # end
  # puts res.to_json
  # # puts items.to_json
end

# rsync -azP rs:/content/prod/rstar/content/dlts/adl/wip/se/adl0962

# rubocop:enable Layout/LineLength
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/BlockLength
