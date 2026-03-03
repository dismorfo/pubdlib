# frozen_string_literal: true

# Need documentation.
class CreateMongoCollection < Command
  @se = nil
  @command = 'create-mongo-collection'
  @label = 'Create MongoDB collection.'
  @description = 'Create a MongoDB collection for a given collection name.'
  @flags = [
    {
      flag: 'name',
      label: 'Collection name.',
      type: String,
      required: true
    }
  ]

  def action(opts)

    require './lib/sequence'

    sequence = Sequence.new()
    puts "Creating MongoDB collection: #{opts.name}"
    sequence.create_with_indexes(opts.name)    
  end

end
