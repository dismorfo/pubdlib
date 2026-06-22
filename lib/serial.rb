# frozen_string_literal: true

require 'json'
require 'erb'
require './lib/mets'

class Serial

  include ERB::Util

  def initialize(se, ticket, script = 'Latn')

    @se = se

    @data = nil

    mets = Mets.new(se, script)

    se_hash = se.hash

    entity_language = 'en'

    # @TODO: fix
    # if script == 'Arab'
    #   lang = mets.language_code
    #   iso_map = JSON.parse(File.read('./datasource/iso-639-2.json'))
    #   entity_language = iso_map[lang.to_s]
    # end

    pdfs = []

    se.fmds.each do |fmd|
      if fmd.name === "#{se.identifier}_hi.pdf"
        pdfs.push(
          type: 'hi',
          uri: "pdfserver://serials/#{se.identifier}/#{se.identifier}_hi.pdf",
          filesize: fmd.filesize,
          searchable: fmd.searchable
        )
      end
      if fmd.name === "#{se.identifier}_lo.pdf"
        pdfs.push(
          type: 'lo',
          uri: "pdfserver://serials/#{se.identifier}/#{se.identifier}_lo.pdf",
          filesize: fmd.filesize,
          searchable: fmd.searchable
      )
      end
    end

    item_data = {
      title: se.title,
      identifier: se.identifier,
      language: entity_language,
      status: 1,
      entity_type: "dlts_serial",
      ticket: ticket,
      noid: se.noid,
      page_count: mets.page_count,
      sequence_count: mets.sequence_count,
      binding_orientation: mets.binding_orientation,
      read_order: mets.read_order,
      scan_order: mets.scan_order,
      representative_image: mets.representative_image,
      metadata: {
        title: {
          label: 'Title',
          value: [se_hash.dig('resource', 'metadata', 'display_title')]
        },
        subtitle: {
          label: 'Subtitle',
          value: mets.subtitle
        },
        author: {
          label: 'Author/Contributor',
          value: mets.authors
        },
        publisher: {
          label: 'Publisher',
          value: [mets.publisher]
        },
        publication_location: {
          label: 'Place of Publication',
          value: mets.publication_location
        },
        publication_date_text: {
          label: 'Date of Publication',
          value: [se_hash.dig('resource', 'metadata', 'date_string')]
        },
        publication_date: {
          label: 'Date of Publication',
          value: [se_hash.dig('resource', 'metadata', 'date')]
        },
        number: {
          label: 'Volume number',
          value: [se_hash.dig('resource', 'metadata', 'number')]
        },
        volume: {
          label: 'Volume Label',
          value: [se_hash.dig('resource', 'metadata', 'volume')]
        },
        collections: {
          label: 'Collections',
          value: se.collections
        },
        partners: {
          label: 'Partners',
          value: se.partners
        },
        handle: {
          label: 'Permanent Link',
          value: [se.handle_url]
        },
        language: {
          label: 'Language',
          value: [mets.language]
        },
        language_code: {
          label: 'Language Code',
          value: [mets.language_code]
        },
        pdfs: {
          label: 'PDFs',
          value: pdfs
        },
        rights: {
          label: 'Rights',
          value: [mets.rights]
        },
        subject: {
          label: 'Subject',
          value: mets.subject
        },
        description: {
          label: 'Description',
          value: mets.physical_description
        },
        scanning_notes: {
          label: 'Notes',
          value: mets.notes
        },
        call_number: {
          label: 'Call Number',
          value: [mets.call_number]
        }
      }
    }
    @data = item_data
  end

  def hash
    @data
  end

  def sequences(se, script = 'Latn')
    mets = Mets.new(se, script)
    mets.sequences
  end

  def save_to_file
    File.write(
      "#{$configuration['CONTENT_DIR']}/serials/#{@data.identifier}.#{@data.language}.json",
      JSON.pretty_generate(@data)
    )
    puts "Saved serial entity to file: #{$configuration['CONTENT_DIR']}/serials/#{@data.identifier}.#{@data.language}.json"
  end

end
