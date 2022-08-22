# frozen_string_literal: true

require 'nice_http'
require 'json'
require 'erb'
require './lib/mods.rb'

# @todo Undocumented Class
class Book
  include ERB::Util
  def initialize(intellectual_entity, source_entity)
    @ie = intellectual_entity
    @se = source_entity
  end

  def json
    hash.to_json
  end

  def mods(script = 'Latn')
    filename = mets.xpath('//mdRef[@MDTYPE="MODS"]/@href').to_s
    filepath = "#{@se.hash.directory_path}/data/#{filename}"
    abort("The file #{filepath} for the resource #{@se.identifier} doesn't exist") unless File.exist?(filepath)

    Mods.new(
      identifier: @se.identifier,
      ieuu: @ie.ieuu,
      script: script,
      is_multivol: @ie.is_multivol,
      need_category: @ie.need_category,
      xml: filepath
    )
  end

  def hash
    items = []
    @need_category = false
    @marc_file_mapping = nil
    @marc_file_path = nil
    # @todo Try to figure out what are we doing here.
    # if options[:marc_file] != nil
    #   @marc_file_mapping = options[:marc_file].split(',')[0]
    #   @marc_file_path = options[:marc_file].split(',')[1]
    #   abort("The file with mapping #{@marc_file_mapping} doesn't exist") unless File.exist?(@marc_file_mapping)
    #   abort("The directory with MARC files #{@marc_file_path} doesn't exist") unless File.exist?(@marc_file_path)
    # end
    mods.scripts.each do |script|
      mod = mods(script)
      item = {
        entity_title: mod.title[0..250],
        identifier: @se.identifier,
        entity_language: mod.entity_language,
        entity_status: '1',
        entity_type: @se.entity_alias,
        ieuu: @ie.ieuu,
        noid: @se.handle,
        metadata: {
          title: {
            label: 'Title',
            value: [
              mod.title
            ]
          },
          subtitle: {
            label: 'Subtitle',
            value: [
              mod.subtitle
            ]
          },
          author: {
            label: 'Author/Contributor',
            value: mod.authors
          },
          publisher: {
            label: 'Publisher',
            value: [
              mod.publisher
            ]
          },
          publication_location: {
            label: 'Place of Publication',
            value: [
              mod.publication_location
            ]
          },
          publication_date_text: {
            label: 'Date of Publication',
            value: [
              mod.pub_date_string
            ]
          },
          publication_date: {
            label: 'Date of Publication',
            value: [
              mod.pub_date
            ]
          },
          topic: {
            label: 'Topic',
            value: mods.topic(@marc_file_mapping, @marc_file_path)
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
            label: 'Permanent Link',
            value: ["http://hdl.handle.net/#{@se.handle}"]
          },
          read_order: {
            label: 'Read Order',
            value: [
              read_order.to_s
            ]
          },
          scan_order: {
            label: 'Scan Order',
            value: [
              scan_order.to_s
            ]
          },
          binding_orientation: {
            label: 'Binding Orientation',
            value: [
              orientation.to_s
            ]
          },
          page_count: {
            label: 'Page count',
            value: [
              sequence_count.to_s
            ]
          },
          sequence_count: {
            label: 'Read Order',
            value: [
              sequence_count.to_s
            ]
          },
          call_number: {
            label: 'Call Number',
            value: mod.call_number(@marc_file_mapping, @marc_file_path)
          },
          identifier: {
            label: 'Identifier',
            value: [
              @se.identifier
            ]
          },
          language: {
            label: 'Language',
            value: [
              mod.language
            ]
          },
          language_code: {
            label: 'Language',
            value: [
              mod.language_code
            ]
          },
          pdfs: {
            label: 'PDF',
            value: @se.pdfs
          },
          representative_image: representative_image,
          rights: {
            label: 'Rights',
            value: [
              mets_rights
            ]
          },
          subject: {
            label: 'Subject',
            value: mod.subject
          },
          multivolume: {
            volume: mod.multivolume(@ie)
          },
          series: mod.series(@ie)
        }
      }

      items.push(item)
    end
    items
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
    @se.hash.isPartOf.each do |item|
      collections.push(
        title: item.name[0, 250],
        name: item.name,
        identifier: item.uuid,
        type: item.type,
        language: 'und',
        code: item.code,
        partner: {
          title: item.provider.name[0, 250],
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
    providers = []
    @se.hash.isPartOf.each do |part_of|
      providers.push(
        title: part_of.provider.name[0, 255],
        name: part_of.provider.name,
        type: part_of.provider.type,
        language: 'und',
        identifier: part_of.provider.uuid,
        code: part_of.provider.code
      )
    end
    providers
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
          height: sequence_metadata.height
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

  def mets
    seuu_path = "#{@se.se_path}/data/#{@se.identifier}_mets.xml"
    abort("The file #{seuu_path} for the resource #{@se.identifier} doesn't exist") unless File.exist?(seuu_path)

    Nokogiri::XML.parse(File.open(seuu_path)).remove_namespaces!
  end

  def mets_rights
    filepath = mets.xpath('//mdRef[@MDTYPE="METSRIGHTS"]/@href').to_s
    rights_file = "#{@se.se_path}/data/#{filepath}"
    abort("The file #{rights_file} for the resource with #{@se.identifier} doesn't exist") unless File.exist?(rights_file)

    xml = Nokogiri::XML.parse(File.open(rights_file)).remove_namespaces!
    xml.xpath('//RightsDeclaration/text()').to_s
  end

  def scan_data
    mets.xpath('//structMap/@TYPE').to_s
  end

  def orientation
    scan_data.split(' ')[1].split(':')[1] =~ /^horizontal$/i ? 1 : 0
  end

  def read_order
    scan_data.split(' ')[2].split(':')[1] =~ /^right(2|_to_)left$/i ? 1 : 0
  end

  def scan_order
    scan_data.split(' ')[3].split(':')[1] =~ /^right(2|_to_)left$/i ? 1 : 0
  end

  def sequence_count
    mets.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').size
  end

  def representative_image
    div = mets.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').first
    label = div.xpath('@ID').to_s.gsub('s-', '')
    metadata = image_metadata "#{@se.type_alias}/#{@se.identifier}/#{label}_d.jp2"
    {
      isPartOf: @se.identifier,
      sequence: [1],
      realPageNumber: 1,
      cm: {
        uri: "fileserver://#{@se.type_alias}/#{@se.identifier}/#{label}_d.jp2",
        width: metadata.width,
        height: metadata.height
      }
    }
  end
end
