# frozen_string_literal: true

require 'json'
require 'erb'
require './lib/mets'
require './lib/ie'

class Book
  include ERB::Util

  attr_reader :data

  def initialize(se, ticket, script = 'Latn')
    @se = se
    @script = script
    @mets = Mets.new(se, script)
    @ie = Ie.new(ie_file_path, se, script)
    @data = build_item_data(ticket)
  end

  def hash
    # @data
  end

  def json
    JSON.pretty_generate(@data)
  end

  def sequences(se, script = 'Latn')
    Mets.new(se, script).sequences
  end

  def save_to_file
    path = "#{$configuration['CONTENT_DIR']}/books/#{@data[:identifier]}.#{@data[:language]}.json"
    File.write(path, json)
    puts "Saved book entity to file: #{path}"
  end

  private

  def build_item_data(ticket)
    {
      title: @mets.title[0..254],
      identifier: @se.identifier,
      language: resolve_language,
      status: 1,
      entity_type: 'dlts_book',
      ticket: ticket,
      noid: @se.noid,
      page_count: @mets.page_count,
      sequence_count: @mets.sequence_count,
      binding_orientation: @mets.binding_orientation,
      read_order: @mets.read_order,
      scan_order: @mets.scan_order,
      representative_image: @mets.representative_image,
      metadata: build_metadata,
      series: @mets.series(@se.collection_code, @se.partner_code),
      multivolume: {
        volume: @ie.books
      }
    }
  end

  def build_metadata
    {
      title: { label: 'Title', value: [@mets.title] },
      subtitle: { label: 'Subtitle', value: @mets.subtitle },
      author: { label: 'Author/Contributor', value: @mets.authors },
      publisher: { label: 'Publisher', value: [@mets.publisher] },
      publication_location: { label: 'Place of Publication', value: @mets.publication_location },
      publication_date_text: { label: 'Date of Publication (string)', value: @mets.publication_date_string },
      publication_date: { label: 'Date of Publication', value: @mets.publication_date(@mets.publication_date_string) },
      call_number: { label: 'Call Number', value: @mets.call_number },
      number: { label: 'Volume number', value: @mets.number },
      collections: { label: 'Collections', value: @se.collections },
      partners: { label: 'Partners', value: @se.partners },
      handle: { label: 'Permanent Link', value: [@se.handle_url] },
      language: { label: 'Language', value: [@mets.language] },
      language_code: { label: 'Language Code', value: [@mets.language_code] },
      pdfs: { label: 'PDFs', value: extract_pdfs },
      rights: { label: 'Rights', value: [@mets.rights] },
      subject: { label: 'Subject', value: @mets.subject },
      description: { label: 'Description', value: @mets.physical_description },
      scanning_notes: { label: 'Notes', value: @mets.notes }
    }
  end

  def extract_pdfs
    @se.fmds.each_with_object([]) do |fmd, pdfs|
      %w[hi lo].each do |type|
        filename = "#{@se.identifier}_#{type}.pdf"
        next unless fmd.name == filename

        pdfs << {
          type: type,
          uri: "pdfserver://books/#{@se.identifier}/#{filename}",
          filesize: fmd.filesize,
          searchable: fmd.searchable
        }
      end
    end
  end

  def resolve_language
    'en'
    # Future implementation:
    # return 'en' unless @script == 'Arab'
    # lang = @mets.language_code
    # iso_map = JSON.parse(File.read('./datasource/iso-639-2.json'))
    # iso_map[lang.to_s] || 'en'
  end

  def ie_file_path
    collection = @se.collections[0]
    ies = @se.hash.resource.ies
    "#{$configuration['RSBE_CONTENT']}/#{collection.partner.code}/#{collection.code}/wip/ie/#{ies[0].ie_id}/data/#{ies[0].ie_id}_mets.xml".to_s
  end
end
