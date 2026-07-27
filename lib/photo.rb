# frozen_string_literal: true

require 'nice_http'
require 'json'
require 'erb'
require 'image_size'

# @todo Undocumented Class
class Photo
  include ERB::Util
  def initialize(source_entity)
    @se = source_entity
    @sequence_count_int = 0
  end

  def json
    hash.to_json
  end

  def hash
    {
      entity_title: @se.resource.digi_id,
      identifier: @se.resource.digi_id,
      entity_language: 'en',
      entity_status: '1',
      entity_type: @se.resource.do_type,
      metadata: {
        title: {
          label: 'Title',
          value: [
            @se.resource.digi_id
          ]
        },
        collection: {
          label: 'Collection',
          value: collections
        },
        partner: {
          label: 'Partner',
          value: partners
        },
        handle: {
          label: 'Permanent link',
          value: [@se.resource.fids.citation_url]
        },
        page_count: {
          label: 'Page count',
          value: [sequence_count]
        },
        sequence_count: {
          label: 'Sequence count',
          value: [sequence_count]
        }
      },
      pages: sequences
    }
  end

  def handle_url
    @se.resource.fids.citation_url
  end

  def handle
    [
      handle_url
    ]
  end

  def collections
    collections = []

    item = @se.collection

    partner = @se.partner

    collection_partner = {}

    if partner.id == item.partner_id
      collection_partner = {
        title: partner.name[0, 255],
        name: partner.name,
        type: 'dlts_partner',
        language: 'und',
        identifier: partner.id,
        code: partner.code
      }
    end

    collections.push(
      title: item.name[0, 255],
      name: item.name,
      identifier: item.id,
      type: 'dlts_collection',
      language: 'und',
      code: item.code,
      partner: collection_partner
    )

    collections
  end

  def partners
    partner = collections[0].partner
    [
      {
        title: partner.name[0, 255],
        name: partner.name,
        type: partner.type,
        language: 'und',
        identifier: partner.identifier,
        code: partner.code
      }
    ]
  end

  # I can do better.
  def sequence_count
    @sequence_count_int = image_files.count if @sequence_count_int < 1
    @sequence_count_int
  end

  def sequences
    sequences = []
    image_files.each.with_index do |file, position|
      image_id = "photo/#{@se.resource.digi_id}/#{File.basename(file)}"
      image_size = ImageSize.path(file)
      order = position + 1
      sequences.push(
        isPartOf: @se.resource.digi_id,
        sequence: [order],
        realPageNumber: order,
        cm: {
          uri: "fileserver://#{image_id}",
          width: image_size.width,
          height: image_size.height
        }
      )
    end
    # We do this to avoing running glob and sort multiple times.
    @sequence_count_int = sequences.count
    {
      page: sequences
    }
  end

  def image_files
    raise "#{@se.directory_path} must exist." unless File.exist?(@se.directory_path)

    files_path = "#{@se.directory_path}/aux"
    files = Dir.glob("#{files_path}/*.jp2")
    raise "JP2 files not found in path: #{files_path}." if files.count.zero?

    files.sort { |a, b| a <=> b }
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

  def save_to_file
    File.write(
      "#{$configuration['CONTENT_DIR']}/photos/#{@se.resource.digi_id}.json",
      JSON.pretty_generate(hash)
    )
    puts "Saved photo entity to file: #{$configuration['CONTENT_DIR']}/photos/#{@se.resource.digi_id}.json"
  end

end
