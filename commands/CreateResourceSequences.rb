# frozen_string_literal: true

class CreateResourceSequences < Command
  @command = 'create-resource-sequences'
  @label = 'Create resource sequences'
  @description = 'Create resource sequences for a given digital identifier.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    },
    {
      flag: 'ticket',
      label: 'Job ticket.',
      type: String
    }
  ]

  def action(opts)

    require './lib/se-experimental'

    se = SeExperimental.new(opts.identifier)
    case se.type
      when 'serial'
        create_serial_sequences(se, opts.ticket)
    end
  end

  def create_serial_sequences(se, ticket)

    require './lib/sequence'
    require './lib/serial'

    entity = Serial.new(se, ticket)

    sequence = Sequence.new()

    sequence.use_collection(entity.hash.entity_type)

    sequence.delete_all(entity.hash.identifier)

    sequence.insert_sequences(entity.hash.sequences)

    sequence.disconnect

  end
end
