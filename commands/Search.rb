# frozen_string_literal: true

require './lib/se'

# Need documentation.
class Search < Command
  @command = 'search'
  @label = 'Search entity source'
  @description = "Search entity source using it's digi_id."
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]

  def action(opts)
    se = Se.new(opts[:identifier])
    puts se.json
  end
end
