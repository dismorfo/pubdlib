# frozen_string_literal: true

require './lib/se'
require './lib/ie'
require './lib/stream'
require './lib/media'
require './lib/viewer.rb'
require './lib/sequence.rb'

# Need documentation.
class Delete < Command
  @se = nil
  @command = 'delete'
  @label = 'Delete item'
  @description = 'Delete  item given a digi_id or identifier'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    },
  ]

  def action(opts)
    @se = Se.new(opts.identifier)
    case @se.type
      when 'image_set'
        delete_image_set
      when 'audio', 'video'
        delete_media
      when 'book'
        delete_book
    end
  end

  def delete_media
    # Wrap source entity as Stream resource.
    # entity = Stream.new(@se)
    # media = Media.new
    # Post resource.
    # req = media.post(entity.json)
    # puts req.to_json
  end

  def delete_book
    ies = IE.new(opts[:identifier], opts[:provider])    
    # puts ies.hash
    puts se.hash
  end

  def delete_image_set
    # Wrap source entity as Photo resource.
    entity = Photo.new(@se.hash)
    # Init Viewer.
    viewer = Viewer.new
    # Delete resource.
    req = viewer.delete(entity)
    
    if req
     # Init sequence and prepare MongoDB.
     sequence = Sequence.new(type: entity.hash.entity_type)
     # Delete any record.
     sequence.delete_all(entity.hash.identifier)
    end
    puts "#{req.status} - #{req.message}"
  end
end
