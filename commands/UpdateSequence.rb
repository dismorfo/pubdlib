# frozen_string_literal: true

require './lib/se'
require './lib/ie'
require './lib/viewer.rb'
require './lib/sequence.rb'

# Need documentation.
class UpdateSequence < Command
  @se = nil
  @command = 'update-sequence'
  @label = 'Update sequence'
  @description = 'Update object sequence'
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
        publish_image_set
      when 'book'
        publish_book
    end
  end

  def publish_book
    # ies = IE.new(opts[:identifier], opts[:provider])
    # puts ies.hash
    # puts @se.hash
  end

  def publish_image_set
    # Wrap source entity as Photo resource.
    entity = Photo.new(@se.hash)
    puts entity.json
    # Init Viewer.
    # viewer = Viewer.new
    # Post resource.
    # req = viewer.post(entity.json)
    # if req
    #   # Init sequence and prepare MongoDB.
    #   sequence = Sequence.new(type: entity.hash.entity_type)
    #   # Delete any record.
    #   sequence.delete_all(entity.hash.identifier)
    #   # Insert all sequences at once.
    #   sequence.insert_sequences(entity.hash.pages.page)
    #   # Disconnect from MongoDB.
    #   sequence.disconnect
    #   # Get profle
    #   profile = @se.hash.profile
    #   # Sequence count.
    #   count = entity.sequence_count.to_i

    #   target = profile.target[$configuration['TARGET']]
    
    #   target.path = target.path.gsub('[identifier]', @se.identifier)
    
    #   target.path = target.path.gsub('[noid]', @se.noid)

    #   # - If SE has one sequence, then it will be publish with thumbnails.
    #   if count == 1
    #     target.path = target.path.gsub('/[?sequence]', '/1')
    #     req.bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
    #   # - If SE has more than one sequence it will be publish without thumbnails.
    #   else      
    #     target.path = target.path.gsub('/[?sequence]', '')
    #     req.bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
    #   end
    # end
    # puts req.to_json
    # puts entity.json
  end
end
