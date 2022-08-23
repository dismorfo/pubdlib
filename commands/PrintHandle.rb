# frozen_string_literal: true

require './lib/se'

# Need documentation.
class PrintHandle < Command
  @se = nil
  @command = 'print-se-handle'
  @label = 'Print source entity handle'
  @description = 'Given a digi_id, print source entity handle.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Digital identifier.',
      type: String
    }
  ]

  def action(opts)
    @se = Se.new(opts[:identifier])
    puts "#{$configuration['HANDLE_REDIRECTS']}/#{@se.handle}" 
  end
end
