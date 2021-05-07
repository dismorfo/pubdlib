# frozen_string_literal: true

require './lib/se'

# Need documentation.
class SeJson < Command
  @se = nil
  @command = 'se-json'
  @label = 'Echo source entity JSON.'
  @description = 'Given a digi_id, echo source entity JSON.'
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
        entity = Photo.new(@se.hash)
        puts entity.json

      when 'video', 'audio'
        entity = Stream.new(@se.hash)
        puts entity.json
    end
  end
end
