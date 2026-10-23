# frozen_string_literal: true

require 'nice_http'
require 'json'
require 'erb'
require './lib/mets'
require 'nokogiri'

# @todo Undocumented Class
class Ie
  include ERB::Util
  @identifier = nil

  def initialize(ie_filepath, se = nil, script = 'Latn')
    if !File.exist?(ie_filepath)
      puts "File #{ie_filepath} does not exist."
      exit
    end

    parser = Saxerator.parser(File.new(ie_filepath))

    identifier = parser.for_tag(:mets).first.attributes['OBJID']

    books = []

    multi_volume = false

    parser.for_tag(:div).with_attributes({:TYPE => 'INTELLECTUAL_ENTITY'}).each do |ie|
      if (!ie.nil?)
        book_identifier = ie['mptr'].attributes['xlink:href'].split('/')[4]
        entity = if book_identifier == se.identifier
                   se
                 else
                   SeExperimental.new(book_identifier)
                 end

        mets = Mets.new(entity, script)
        volume = ie.attributes['ORDERLABEL']
        volume_order = ie.attributes['ORDER']
        books << {
          identifier: identifier,
          volume_number_str: volume,
          volume_number: volume_order,
          collection: entity.collections,
          isPartOf: {
            title: mets.title,
            type: 'dlts_multivol',
            language: 'und',
            identifier: book_identifier
          }
        }
      end
    end

    if books.size > 1
      multi_volume = true
    else
      if books[0][1] != nil
        multi_volume = true
      end
    end
    @books = books
    @multi_volume = multi_volume
  end

  def multivolume?
    @multi_volume
  end

  attr_reader :identifier, :books
end
