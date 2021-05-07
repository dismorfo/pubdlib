# frozen_string_literal: true

require 'mongo'

# Undocumented function.
class Sequence
  include Mongo
  def initialize(_configuration)
    # puts configuration[:type]
    collection = 'dlts_photo'
    @client = client
    @db = database(collection)
  end

  def client
    # set logger level to FATAL (only show serious errors)
    Mongo::Logger.logger.level = ::Logger::FATAL
    # Init MongoDB.
    Mongo::Client.new($configuration['MONGO_URL'], database: $configuration['MONGO_DATABASE'])
  end

  def database(collection)
    client.database[collection]
  end

  def pick_one(identifier, sequence)
    @db.find(isPartOf: identifier, sequence: sequence).first
  end

  def find(identifier)
    items = []
    result = @db.find(isPartOf: identifier)
    result.sort(realPageNumber: 1).each do |document|
      items.push(document.except(:_id))
    end
    items
  end

  def delete_all(identifier)
    @db.find(isPartOf: identifier).delete_many
  end

  def delete(identifier, sequence)
    result = @db.find(isPartOf: identifier, sequence: sequence).delete_one

    result.deleted_count
  end

  def insert_sequences(sequences)
    delete_all(sequences[0].isPartOf)
    @db.insert_many(sequences)
  end

  def save(sequence)
    result = @db.find(isPartOf: sequence.isPartOf, sequence: sequence.sequence)
                .first
    # Update
    if result
      doc = @db.find(isPartOf: sequence.isPartOf, sequence: sequence.sequence)
               .find_one_and_replace(sequence, return_document: :after)
      doc
    # Create
    else
      @db.insert_one(sequence)
    end
  end

  def disconnect
    @client.close
  end
end
