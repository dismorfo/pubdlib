# frozen_string_literal: true

class Publish < Command
  @command = 'publish'
  @label = 'Publish item'
  @description = 'Publish item given a digi_id'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String,
      required: true
    },
    {
      flag: 'ticket',
      label: 'Job ticket.',
      type: String
    },
    {
      flag: 'experimental',
      label: 'Use experimental features.',
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

    # type = data.resource.do_type || raise('Missing required do_type in resource')
    type = (data.resource&.do_type || data&.type) || raise('Missing required type in resource')

    @experimental = ["true", "t", "1", "yes"].include?(opts.experimental.to_s.downcase)

    identifier = opts.identifier

    ticket = opts.ticket || 'DLTS-XXXX'

    case type
      when 'serial'
        publish_serial(identifier, ticket)
      when 'image_set', 'dlts_photo_set'
        publish_image_set(identifier, ticket)
      when 'dlts_map', 'map'
        publish_map(identifier, ticket)
      when 'book'
        publish_book(identifier, ticket)
      when 'audio', 'video'
        publish_media(identifier, ticket)
    end
  end

  def publish_map(identifier, ticket)
  end

  def publish_media(identifier, _ticket)

    # Required dependencies.
    require './lib/se'
    require './lib/stream'
    require './lib/media'

    se = Se.new(identifier)

    # Wrap source entity as Stream resource.
    entity = Stream.new(identifier)

    media = Media.new

    # Post resource.
    req = media.post(entity.json)

    puts req.to_json

  end

  # ./pubdlib.rb publish --identifier "fales_sc000038" -e "./config.local.json" --ticket "DLTSBOOKS-333"
  def publish_book(identifier, ticket)
    # Required dependencies.
    # https://nyu.atlassian.net/browse/DLTSBOOKS-333
    require './lib/se-experimental'
    require './lib/book'
    require './lib/viewer'
    require './lib/sequence'

    se = SeExperimental.new(identifier)

    entity = Book.new(se, ticket)

    sequences = entity.sequences(se)

    entity.save_to_file

    # Init Viewer.
    viewer = Viewer.new

    # Post resource.
    req = viewer.post(entity.hash.to_json)

    if req

      sequence = Sequence.new

      sequence.use_collection('dlts_books_page')

      sequence.delete_all(entity.hash.identifier)

      sequence.insert_sequences(sequences)

      sequence.disconnect

      puts "Published book with identifier: #{identifier}"

      entity.save_to_file

    end

  end

  def publish_serial(identifier, ticket)
    # Required dependencies.
    require './lib/se-experimental'
    require './lib/serial'
    require './lib/viewer'
    require './lib/sequence'

    se = SeExperimental.new(identifier)

    entity = Serial.new(se, ticket)

    # Init Viewer.
    viewer = Viewer.new

    # Post resource.
    req = viewer.post(entity.hash.to_json)

    if req

      sequences = entity.sequences(se)

      sequence = Sequence.new

      sequence.use_collection(entity.hash.entity_type)

      sequence.delete_all(entity.hash.identifier)

      sequence.insert_sequences(sequences)

      sequence.disconnect

      puts "Published serial with identifier: #{identifier}"

      entity.save_to_file
    end
  end

  def publish_image_set(identifier, _ticket)
    # Required dependencies.
    require './lib/se'
    require './lib/photo'
    require './lib/sequence'
    require './lib/viewer'

    se = Se.new(identifier)

    # Wrap source entity as Photo resource.
    entity = Photo.new(se.hash)

    # Init Viewer.
    viewer = Viewer.new
    # Post resource.
    req = viewer.post(entity.json)

    if req

      sequence = Sequence.new

      sequence.use_collection('dlts_photo')

      sequence.delete_all(entity.hash.identifier)

      sequence.insert_sequences(entity.hash.pages.page)

      sequence.disconnect

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
        req.bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
      # - If SE has more than one sequence it will be publish without thumbnails.
      else
        target.path = target.path.gsub('/[?sequence]', '')
        req.bind_uri = "#{target.mainEntityOfPage}/#{target.path}"
      end
    end
    puts "Published image set with identifier: #{identifier}"
    puts entity.json
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
