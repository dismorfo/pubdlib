#!/usr/bin/env ruby

# frozen_string_literal: true

require 'rubygems'
require 'optimist'
require 'dotenv/load'
require './lib/se'
require './lib/photo'
require './lib/book'
require './lib/viewer'
require './lib/sequence'
require './lib/handle'

# rubocop:disable Layout/CaseIndentation

SUB_COMMANDS = %w[publish delete link-handle json].freeze

# Application message to display as banner in the help menu.
banner = <<~BANNER
  Usage: ./viewercli.rb -i digitalIdentifier
  Examples:
    $ ./viewercli.rb -i fales_mss222_cuid28860 json  | jq .
    $ ./viewercli.rb -i fales_mss222_cuid28861 | jq .
  where [options] are:
BANNER

opts = Optimist.options do
  version 'viewercli 0.0.1'
  banner banner
  opt :identifier, 'Digital identifier.', type: String
  opt :loud, 'Log to console.', type: Boolean
  opt :environment, 'Environment file to use.', type: String
end

if opts[:identifier].nil?
  Optimist.die :identifier, 'Missing argument identifier.'
end

# load environment variables
# first value set for a variable will win.
Dotenv.load(opts[:environment])

# Username for Repository search endpoint.
Dotenv.require_keys('SE_USER')
# Password for Repository search endpoint.
Dotenv.require_keys('SE_PASS')
# Repository search endpoint.
Dotenv.require_keys('SE_ENDPOINT')
# RSBE content.
Dotenv.require_keys('RSBE_CONTENT')
# Image server.
Dotenv.require_keys('IMAGE_SERVER')
# MongoDb URL
Dotenv.require_keys('MONGO_URL')
# MongoDB database
Dotenv.require_keys('MONGO_DATABASE')
# Handle server.
Dotenv.require_keys('HANDLE_URL')
# Handle user.
Dotenv.require_keys('HANDLE_USER')
# Handle pass.
Dotenv.require_keys('HANDLE_PASS')
# Location of content repository
Dotenv.require_keys('CONTENT_REPOSITORY_PATH')

Dotenv.require_keys('VIEWER_ENDPOINT')
Dotenv.require_keys('VIEWER_USER')
Dotenv.require_keys('VIEWER_PASS')

def generate_json_image_set(se)
  entity = Photo.new(se.hash)
  entity_language = 'en'
  f_json = File.open("#{ENV['CONTENT_REPOSITORY_PATH']}/#{se.type_alias}/#{se.identifier}.#{entity.hash.entity_language}.json", 'w')
  f_json.write(entity.json)
  f_json.close
end

def generate_json(identifier)
  se = Se.new(identifier)
  case se.type
  when 'image_set'
    generate_json_image_set(se)
  end
end

def publish_image_set(se)
  # Wrap source entity as Photo resource.
  entity = Photo.new(se.hash)
  # Init Viewer.
  viewer = Viewer.new
  # Post resource.
  viewer.post(entity.json)
  # Init sequence and prepare MongoDB.
  sequence = Sequence.new(type: entity.hash.entity_type)
  # Delete any record.
  sequence.delete_all(se.identifier)
  # Insert all sequences at once.
  sequence.insert_sequences(entity.hash.pages.page)
  # Disconnect from MongoDB.
  sequence.disconnect
  # Get profle
  profile = se.hash.profile
  # Sequence count. 
  count = entity.sequence_count.to_i
  # - If SE has one sequence, then it will be publish with thumbnails.
  if count == 1
    bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[se.type]}/#{se.identifier}/1"
  # - If SE has more than one sequence it will be publish without thumbnails.
  else
    bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[se.type]}/#{se.identifier}"
  end
  # Init handle  
  handle = Handle.new
  # Bind handle
  handle.bind(se.handle, bind_uri)
end

def publish(identifier)
  se = Se.new(identifier)
  case se.type
  when 'image_set'
    publish_image_set(se)

  when 'audio'
    puts se.json

  end
end

def link_handle(identifier)
  se = Se.new(identifier)
  profile = se.hash.profile

  case se.type
  when 'image_set'
    photo = Photo.new(se.hash)
    count = photo.sequence_count.to_i

    # "WITH" OR "WITHOUT" thumbnail
    # @link https://jira.nyu.edu/jira/browse/DLTSIMAGES-325?focusedCommentId=1500278&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-1500278

    # - If SE has one sequence, then it will be publish with thumbnails
    if count == 1
      bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[se.type]}/#{identifier}/1"
    # - If SE has more than one sequence it will be publish without thumbnails
    else
      bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[se.type]}/#{identifier}"
    end

    handle = Handle.new

    handle.bind(se.handle, bind_uri)

  end
end

cmd = ARGV.shift

case cmd
  when 'publish'
    publish opts[:identifier]

  when 'json'
    puts generate_json opts[:identifier]

  when 'link-handle'
    link_handle opts[:identifier]

  else
    Optimist.die "Unknown subcommand #{cmd.inspect}."
end

# se = Se.new(opts[:identifier])

# photo.hash.pages.page.each do |item|
  # puts sequence.pick_one(item.isPartOf.to_s, item.sequence[0])
  # puts sequence.delete(item.isPartOf.to_s, item.sequence[0])
  # sequence.save(item)
# end

# rubocop:enable Layout/CaseIndentation
