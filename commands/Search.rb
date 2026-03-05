# frozen_string_literal: true

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
    require './lib/se'
    se = Se.new(opts[:identifier])
    puts se.json
  end
end
