# frozen_string_literal: true

# https://github.com/brianmario/mysql2
require 'mysql2'

# Need documentation.
class UpdateSequence < Command
  @command = 'update-sequence'
  @label = 'Update sequence'
  @description = "Update sequence."
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]
  def action(opts)
    client = Mysql2::Client.new({ 
      host: $configuration['VIEWER_DB_HOST'], 
      username: $configuration['VIEWER_DB_USER'],
      password: $configuration['VIEWER_DB_PASS'],
      database: $configuration['VIEWER_DB_DATABASE']
    })
    # escaped = client.escape("gi'thu\"bbe\0r's")
    client.query("SELECT * FROM node").each do |row|
      # do something with row, it's ready to rock.
      puts row.title
    end
  end
end
