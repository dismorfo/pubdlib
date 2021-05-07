# frozen_string_literal: true

require './lib/jira'

# Need documentation.
class DownloadTicketFiles < Command
  @command = 'download-ticket-files'
  @label = 'Download files from ticket.'
  @description = 'Download files attached to ticket.'
  @flags = [
    {
      flag: 'ticket',
      label: 'Ticket id.',
      type: String
    }
  ]

  def action(opts)
    jira = Jira.new
    jira.download_attachments(opts[:ticket])
  end
end
