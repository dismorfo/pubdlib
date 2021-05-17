# frozen_string_literal: true

require './lib/se'
require './lib/ie'
require './lib/viewer.rb'

# Need documentation.
class PublishBook < Command
  @ies = nil
  @command = 'publish-book'
  @label = 'Publish book item'
  @description = 'Publish item given a provider and intellectual entity Id'
  @flags = [
    {
      flag: 'identifier',
      label: 'Intellectual entity Id.',
      type: String
    },
    {
      flag: 'Provider',
      label: 'provider list separated by comma.',
      type: String
    }
  ]

  def action(opts)
    abort 'Flag IE unique identifier is required.' if opts[:identifier].nil?
    abort('Flag providers is required.') if opts[:provider].nil?

    @ies = IE.new(opts[:identifier], opts[:provider])

    @ies.hash
  end
end
