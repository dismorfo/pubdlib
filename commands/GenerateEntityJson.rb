# frozen_string_literal: true

require './lib/se'
require './lib/photo'
require './lib/stream'

# Need documentation.
class GenerateEntityJson < Command
  @command = 'generate-entity-json'
  @label = 'Generate entity JSON.'
  @description = 'description'
  @flags = [
    {
      flag: 'identifier',
      label: 'Identifier. E.g., -i digi_id',
      type: String
    }
  ]

  @se = nil

  def action(opts)
    abort 'Must give identifier' if opts[:identifier].nil?
    @se = Se.new(opts[:identifier])
    case @se.type
      when 'image_set'
        entity = Photo.new(@se)
      when 'audio', 'video'
        entity = Stream.new(@se)
    end
    generate_json entity
  end

  def generate_json(entity)
    filepath = "#{$configuration['CONTENT_REPOSITORY_PATH']}/#{@se.type_alias}/#{@se.identifier}.#{entity.hash.entity_language}.json"
    temp_write_json = File.open(filepath, 'w')
    temp_write_json.write(entity.json)
    temp_write_json.close
    puts "Entity #{@se.identifier} saved as #{filepath}"
  end
end
