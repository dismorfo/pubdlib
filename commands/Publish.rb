# frozen_string_literal: true

require './lib/se'
require './lib/stream'
require './lib/media'

# Need documentation.
class Publish < Command
  @se = nil
  @command = 'publish'
  @label = 'Publish item'
  @description = 'Publish item given a digi_id'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]

  def action(opts)
    @se = Se.new(opts[:identifier])
    case @se.type
      when 'image_set'
        publish_image_set
      when 'audio', 'video'
        publish_media
    end
  end

  def publish_media
    # Wrap source entity as Photo resource.
    entity = Stream.new(@se)
    media = Media.new
    # Post resource.
    req = media.post(entity.json)
    puts req.to_json
  end

  def publish_book
    puts @se.hash
  end

  def publish_image_set
    # Wrap source entity as Photo resource.
    entity = Photo.new(@se.hash)
    # Init Viewer.
    viewer = Viewer.new
    # Post resource.
    viewer.post(entity.json)
    # Init sequence and prepare MongoDB.
    sequence = Sequence.new(type: entity.hash.entity_type)
    # Delete any record.
    sequence.delete_all(se.identifier)
    # Insert all sequences at once.
    sequence.insert_sequences(entity.hash.pages.page)
    # Disconnect from MongoDB.
    sequence.disconnect
    # Update Handle
    # Get profle
    # profile = @se.hash.profile
    # # Sequence count.
    # count = entity.sequence_count.to_i
    # # - If SE has one sequence, then it will be publish with thumbnails.
    # if count == 1
    #   bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[@se.type]}/#{@se.identifier}/1"
    # # - If SE has more than one sequence it will be publish without thumbnails.
    # else
    #   bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[@se.type]}/#{@se.identifier}"
    # end
    # # Init handle
    # handle = Handle.new
    # # Bind handle
    # handle.bind(se.handle, bind_uri)
  end
end
