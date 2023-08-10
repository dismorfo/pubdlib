# frozen_string_literal: true

# See: https://iiif.io/api/presentation/3.0/.
class CreteIIIFManifest < Command
  @command = 'create-iiif-manifest'
  @label = 'Create IIIF Presentation manifest.'
  @description = 'Create IIIF Presentation  version 3 manifest.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]

  def action(opts)
    # Example id of photo: AD-MC-026_ref26
    se = Se.new(opts.identifier)
    case se.type
      when 'image_set'
        entity = Photo.new(se)
      when 'video', 'audio'
        entity = Stream.new(se)
    end

    puts se.hash.to_json

    # { "label": { "en": [ "Example Object Title" ] } }

  end
end
