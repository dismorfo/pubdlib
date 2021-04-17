#!/usr/bin/env ruby

# frozen_string_literal: true

require 'rubygems'
require 'optimist'
require 'dotenv/load'
require './lib/se'
require './lib/photo'
require './lib/viewer'
require './lib/sequence'

# load environment variables
# first value set for a variable will win.
Dotenv.load(
  '.env.production',
  '.env.stage',
  '.env.development',
  '.env.local',
  '.env'
)

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

# Application message to display as banner in the help menu.
banner = <<~BANNER
  Usage: ./import-photo-json.rb -i digitalIdentifier
  Examples:
    $ ./import-photo-json.rb -i fales_mss222_cuid28860 | jq .
    $ ./import-photo-json.rb -i fales_mss222_cuid28861 | jq .
  where [options] are:
BANNER

opts = Optimist.options do
  version 'import-photo-json 0.0.1'
  banner banner
  opt :identifier, 'Digital identifier.', type: String
end

if opts[:identifier].nil?
  Optimist.die :identifier, 'Missing argument identifier.'
end

se = Se.new(opts[:identifier])

photo = Photo.new(se.hash)

# viewer = Viewer.new

# viewer.post(photo.json)

sequence = Sequence.new(type: photo.hash.entity_type)

puts sequence.find(opts[:identifier]).to_json

# sequence.delete_all(opts[:identifier])

# Danger zone. Delete all first, and then insert.
# sequence.insert_sequences(photo.hash.pages.page)

photo.hash.pages.page.each do |item|
  # puts sequence.pick_one(item.isPartOf.to_s, item.sequence[0])
  # puts sequence.delete(item.isPartOf.to_s, item.sequence[0])
  # sequence.save(item)
end

sequence.disconnect
