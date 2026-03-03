# frozen_string_literal: true

require './lib/se-experimental'
require './lib/serial'
require './lib/sequence'

# Need documentation.
# ./pubdlib.rb list-resource-sequences --identifier "fales_ear000001" -e "config.local.json" --ticket "DLTSSER-28"
class ListResourceSequences < Command
  @command = 'list-resource-sequences'
  @label = 'List resource sequences'
  @description = 'List resource sequences for a given digital identifier.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]

  def initialize
    @http = authenticate
  end

  def action(opts)

    request = {
      path: "/api/v1/repository/search?digi_id=#{opts.identifier}"
    }
    
    resp = @http.get(request)
    raise 'Unable to search service.' unless resp.code == 200    

    data = JSON.parse(resp.data)

    type = data.resource.do_type || raise("Missing required do_type in resource")

    case type
      when 'serial'
        type = 'dlts_serial'
      when 'image_set'
        type = 'dlts_photo'
      when 'dlts_photo_set'
        type = 'dlts_photo'
      when 'image_set'
        type = 'dlts_photo'
      when 'dlts_map'
        type = 'dlts_map_page'
      when 'book'
        type = 'dlts_books_page'
    end

    sequences = list_sequences(opts.identifier, type)

    puts JSON.pretty_generate(sequences)

  end

  def list_sequences(identifier, entity_type)

    sequence = Sequence.new()

    sequence.use_collection(entity_type)

    sequences = sequence.find(identifier)

    sequence.disconnect

    sequences

  end

  def authenticate
    http = NiceHttp.new($configuration['VIEWER_ENDPOINT'])
    request = {
      path: '/api/v0/import/user/login.json',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        'username': $configuration['VIEWER_USER'],
        'password': $configuration['VIEWER_PASS']
      }
    }
    resp = http.post(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end

end
