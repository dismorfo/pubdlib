# frozen_string_literal: true

# Need documentation.
class GenerateEntityJson < Command
  @command = 'generate-entity-json'
  @label = 'Generate entity JSON.'
  @description = 'description'
  @flags = [
    {
      flag: 'identifier',
      label: 'Identifier. E.g., -i digi_id',
      type: String,
      required: true
    }
  ]

  def action(opts)
    abort 'Must give identifier' if opts[:identifier].nil?

    require './lib/se'

    se = Se.new(opts[:identifier])
    case se.type
      when 'image_set'
        require './lib/photo'
        entity = Photo.new(se.hash)
      when 'audio', 'video'
        require './lib/stream'
        entity = Stream.new(se)
    end
    filepath = "#{$configuration['CONTENT_REPOSITORY_PATH']}/#{se.type_alias}/#{entity.hash.identifier}.#{entity.hash.entity_language}.json"
    temp_write_json = File.open(filepath, 'w')
    temp_write_json.write(entity.json)
    temp_write_json.close
    puts "Entity #{se.identifier} saved as #{filepath}"
  end
end
