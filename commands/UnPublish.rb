# frozen_string_literal: true

require './lib/se'
require './lib/ie'
require './lib/stream'
require './lib/media'
require './lib/viewer.rb'
require './lib/sequence.rb'

# Need documentation.
class UnPublish < Command
  @se = nil
  @command = 'unpublish'
  @label = 'Unpublish item'
  @description = 'Unpublish item given a digi_id'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    },
    {
      flag: 'provider',
      label: 'provider list separated by comma.',
      type: String
    },
    {
      flag: 'entityid',
      label: 'Intellectual entity Id.',
      type: String
    },
  ]

  def action(opts)
    @se = Se.new(opts.identifier)
    case @se.type
      when 'image_set'
        unpublish_image_set
      when 'audio', 'video'
        unpublish_media
      when 'book'
        # abort 'Flag entityid unique identifier is required.' if opts[:entityid].nil?
        # abort('Flag providers is required.') if opts[:provider].nil?
        unpublish_book
    end
  end

  def unpublish_media
    # Wrap source entity as Stream resource.
    entity = Stream.new(@se)
    media = Media.new
    # Post resource.
    # req = media.post(entity.json)
    # puts req.to_json
  end

  def unpublish_book
    ies = IE.new(opts[:identifier], opts[:provider])    
    # puts ies.hash
    puts @se.hash
  end

  def unpublish_image_set
    # Wrap source entity as Photo resource.
    entity = Photo.new(@se.hash)
    # Init Viewer.
    viewer = Viewer.new
    # Post resource.
    # req = viewer.post(entity.json)
    # if req
    #  # Init sequence and prepare MongoDB.
    #  sequence = Sequence.new(type: entity.hash.entity_type)
    #  # Delete any record.
    #  sequence.delete_all(entity.hash.identifier)
    # end
    # puts req.to_json
  end
end
