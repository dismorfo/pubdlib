# frozen_string_literal: true

require 'csv'
require './lib/se'
require './lib/handle'
require './lib/photo'
require './lib/book'

# Need documentation.
class UpdateHandleByNoid < Command
  @command = 'update-handle-by-noid'
  @label = 'Update handle by noid.'
  @description = 'Update handle by noid.'
  @flags = [
    {
      flag: 'noid',
      label: 'noid.',
      type: String
    }
  ]

  def action(opts)

    CSV.foreach('/home/aof1/tools/pubdlib/jobs/DLTSVIDEO-179-fales-gcn-se-noid-list.csv', headers: true).with_index do |row, i|
      identifier = row[0]
      if !identifier.empty?
        se = Se.new(identifier)
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
          handle = Handle.new
          # handle.bind(se.handle, bind_uri)
        when 'book'
          # Get profle
          profile = se.hash.profile
          # Target 
          target = profile.target[$configuration['TARGET']]
          target.path = target.path.gsub('[identifier]', se.identifier)
          target.path = target.path.gsub('[noid]', se.noid)
          target.path = target.path.gsub('/[?sequence]', '/1')
          bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
          handle = Handle.new
          # handle.bind(se.handle, bind_uri)
        when 'video', 'audio'
          target = se.profile.target[$configuration['TARGET']]
          target.path = target.path.gsub('[identifier]', se.identifier)
          target.path = target.path.gsub('[noid]', se.noid)
          bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
          handle = Handle.new
          handle.bind(se.handle, bind_uri)
        end
      end
    end
  end
end
