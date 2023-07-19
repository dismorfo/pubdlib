# frozen_string_literal: true

require 'mongo'
require 'nice_http'
require 'json'
require 'erb'

# Need documentation.
class UpdateSequence < Command
  include ERB::Util
  include Mongo
  @command = 'update-sequence'
  @label = 'Update sequence'
  @description = "Update sequence."
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]

  def image_metadata(image_id)
    http = NiceHttp.new($configuration['IMAGE_SERVER'])
    request = {
      path: "/iiif/2/#{url_encode(image_id)}/info.json"
    }
    resp = http.get(request)
    if resp.code == 200
      return JSON.parse(resp.data)
    else
      # "#{$configuration['IMAGE_SERVER']}/iiif/2/#{url_encode(image_id)}/info.json"
      false
    end
  end

  def action(opts)

    collection = "dlts_books_page"

    client = Mongo::Client.new("#{$configuration['MONGO_URL']}/#{$configuration['MONGO_DATABASE']}")

    sequences = client[:"#{collection}"].find({ 'cm.width': { "$eq": "" } }).limit(500).each do |document|
      metadata = image_metadata document.cm.uri.gsub('fileserver://', '')
      
      if metadata
        client[:"#{collection}"].update_one(
          { '_id': document[:_id] },
          { 
            '$set': { 
              'cm.width': metadata.width, 
              'cm.height': metadata.height,
            },
            '$unset': { 
              'cm.levels': '',
              'cm.dwtLevels': '',
              'cm.compositingLayerCount': '',
            }
          }
        )

        last_updated_record = client[:"#{collection}"].find({ '_id': document[:_id] }).limit(1).first

        puts last_updated_record.to_json if last_updated_record
      end

    end

  end
end
