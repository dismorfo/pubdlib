# frozen_string_literal: true

require './lib/jira'

# Need documentation.
class ReadTicket < Command
  @command = 'read-ticket'
  @label = 'Read ticket in your terminal.'
  @description = 'Download files attached to ticket.'
  @flags = [
    {
      flag: 'ticket',
      label: 'Ticket id.',
      type: String
    },
    {
      flag: 'show_comments',
      label: 'Include comments in output.',
      type: String
    }
  ]

  def action(opts)
    jira = Jira.new
    puts jira.read_ticket opts[:ticket]
  end
end
