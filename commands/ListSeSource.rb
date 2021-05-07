# frozen_string_literal: true

# Need documentation.
class ListSeSource < Command
  @command = 'list-ticket-ses'
  @label = 'List ticket source entity source.'
  @description = 'description'
  @flags = [
    {
      flag: 'ticket',
      label: 'Ticke Id.',
      type: String
    }
  ]
  @ticket = ''

  def action(opts)
    abort 'Must give ticket' if opts[:ticket].nil?

    @ticket = opts[:ticket]

    puts @ticket

    se_identifiers.each do |identifier|
      puts identifier.strip
    end
  end

  def se_ticket_file
    "#{$configuration['JOBS_DIR']}/#{@ticket}-se-list.txt"
  end

  def se_identifiers
    identifiers = []
    File.foreach(se_ticket_file) do |identifier|
      identifiers.push(identifier.strip)
    end
    identifiers
  end
end
