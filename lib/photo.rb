# frozen_string_literal: true

require 'nice_http'
require 'json'
require 'erb'

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
      entity_title: @se.digi_id,
      identifier: @se.digi_id,
      entity_language: 'en',
      entity_status: '1',
      entity_type: @se.type,
      metadata: {
        title: {
          label: 'Title',
          value: [
            @se.digi_id
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
          value: handle
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
    "http://hdl.handle.net/#{@se.handle}"
  end

  def handle
    [
      handle_url
    ]
  end

  def collections
    collections = []
    @se.isPartOf.each do |item|
      collections.push(
        title: item.name[0, 255],
        name: item.name,
        identifier: item.uuid,
        type: item.type,
        language: 'und',
        code: item.code,
        partner: {
          title: item.provider.name[0, 255],
          name: item.provider.name,
          type: item.provider.type,
          language: 'und',
          identifier: item.provider.uuid,
          code: item.provider.code
        }
      )
    end
    collections
  end

  def partners
    provider = @se.isPartOf[0].provider
    [
      title: provider.name[0, 255],
      name: provider.name,
      type: provider.type,
      language: 'und',
      identifier: provider.uuid,
      code: provider.code
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
      image_id = "photo/#{@se.digi_id}/#{File.basename(file)}"
      sequence_metadata = image_metadata(image_id)
      order = position + 1
      sequences.push(
        isPartOf: @se.digi_id,
        sequence: [order],
        realPageNumber: order,
        cm: {
          uri: "fileserver://#{image_id}",
          width: sequence_metadata.width,
          height: sequence_metadata.height,
          levels: '',
          dwtLevels: '',
          compositingLayerCount: '',
          timestamp: Time.now.to_i.to_s
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
end
