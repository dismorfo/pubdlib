# frozen_string_literal: true

require './lib/se'
require './lib/handle'
require './lib/photo'
require './lib/book'

# Need documentation.
class LinkHandle < Command
  @command = 'link-handle'
  @label = 'Link handle.'
  @description = 'Link handle.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Identifier.',
      type: String,
      required: true
    }
  ]

  def action(opts)
    se = Se.new(opts.identifier)
    se_handle = nil
    bind_uri = nil
    case se.type
    when 'image_set'
      entity = Photo.new(se.hash)
      # Get profle
      profile = se.hash.profile
      # Sequence count.
      count = entity.sequence_count.to_i
      target = profile.target[$configuration['TARGET']]
      target.path = target.path.gsub('[identifier]', se.identifier)
      target.path = target.path.gsub('[noid]', se.noid)
      # - If SE has one sequence, then it will be publish with thumbnails.
      if count == 1
        target.path = target.path.gsub('/[?sequence]', '/1')
        bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
      # - If SE has more than one sequence it will be publish without thumbnails.
      else      
        target.path = target.path.gsub('/[?sequence]', '')
        bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
      end
      se_handle = se.handle
    when 'book'
      # Get profle
      profile = se.hash.profile
      # Target 
      target = profile.target[$configuration['TARGET']]
      target.path = target.path.gsub('[identifier]', se.identifier)
      target.path = target.path.gsub('[noid]', se.noid)
      target.path = target.path.gsub('/[?sequence]', '/1')
      bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
      se_handle = se.handle
    when 'video', 'audio'
      target = se.profile.target[$configuration['TARGET']]
      target.path = target.path.gsub('[identifier]', se.identifier)
      target.path = target.path.gsub('[noid]', se.noid)
      bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
      se_handle = se.handle
    end

    if $configuration['TARGET'] === 'development'
      se_handle = se_handle.gsub('2333.1', '10676')
    end

    if se_handle && bind_uri
      handle = Handle.new
      handle.bind(se_handle, bind_uri)
    end

  end
end
