# frozen_string_literal: true

require 'mongo'

# Sequence handler for MongoDB collections.
class Sequence
  include Mongo

  def initialize
    # Establish the connection pool using global configuration
    @client = init_client
    # Initialize the database handle as nil; must be set via use_collection or similar
    @db = nil
  end

  def init_client
    Mongo::Logger.logger.level = ::Logger::FATAL
    Mongo::Client.new($configuration['MONGO_URL'])
  rescue => e
    puts "Failed to connect: #{e.message}"
    raise e
  end

  # Explicitly set the collection context
  def use_collection(name)
    @db = @client.use($configuration['MONGO_DATABASE']).database[name]
    self
  end

  # Creates a collection (lazily) and defines necessary indexes
  def create_with_indexes(name)
    use_collection(name)
    ensure_indexes
  end

  def ensure_indexes
    raise 'No collection selected. Call use_collection first.' unless @db

    # Define indexes simply
    indexes = [
      { key: { isPartOf: 1 }, options: {} },
      { key: { isPartOf: 1, sequence: 1 }, options: { unique: true } },
      { key: { isPartOf: 1, realPageNumber: 1 }, options: {} }
    ]

    indexes.each do |spec|
      # create_one expects (key_hash, options_hash)
      @db.indexes.create_one(spec[:key], spec[:options] || {})
    end
  rescue Mongo::Error::OperationFailure => e
    if e.code == 13
      puts "Skipping index creation: Server is in protected mode (Error 13)."
    else
      puts "Index Note: #{e.message}"
    end
  rescue => e
    puts "Unexpected error creating indexes: #{e.message}"
  end

  def pick_one(identifier, sequence)
    raise 'No collection selected.' unless @db
    @db.find(isPartOf: identifier, sequence: sequence).first
  end

  def find(identifier)
    raise 'No collection selected.' unless @db
    items = []
    result = @db.find(isPartOf: identifier)
    result.sort(realPageNumber: 1).each do |document|
      items.push(document.except(:_id))
    end
    items
  end

  def delete_all(identifier)
    raise 'No collection selected.' unless @db
    @db.find(isPartOf: identifier).delete_many
  end

  def delete(identifier, sequence)
    raise 'No collection selected.' unless @db
    result = @db.find(isPartOf: identifier, sequence: sequence).delete_one
    result.deleted_count
  end

  def insert_sequences(sequences)
    raise 'No collection selected.' unless @db
    return if sequences.nil? || sequences.empty?

    # Detect identifier from Hash or Object
    first = sequences.first
    id = first.is_a?(Hash) ? first['isPartOf'] : first.isPartOf
    
    delete_all(id)
    @db.insert_many(sequences)
  end

  def save(sequence)
    raise 'No collection selected.' unless @db
    
    # Detect keys from Hash or Object
    is_part_of = sequence.is_a?(Hash) ? sequence['isPartOf'] : sequence.isPartOf
    seq_num = sequence.is_a?(Hash) ? sequence['sequence'] : sequence.sequence
    
    filter = { isPartOf: is_part_of, sequence: seq_num }
    
    if @db.find(filter).first
      @db.find(filter).find_one_and_replace(sequence, return_document: :after)
    else
      @db.insert_one(sequence)
    end
  end

  def debug_auth_status
    # Runs the 'connectionStatus' command on the drupal database
    result = @client.use($configuration['MONGO_DATABASE']).database.command(connectionStatus: 1).first
    
    auth_users = result['authInfo']['authenticatedUsers']
    
    if auth_users.empty?
      puts "No user authenticated (Connected as anonymous/guest)."
    else
      auth_users.each do |user|
        puts "Authenticated as: #{user['user']} (DB: #{user['db']})"
      end
    end
  rescue => e
    puts "Could not retrieve auth status: #{e.message}"
  end

  def disconnect
    @client.close
  end
end