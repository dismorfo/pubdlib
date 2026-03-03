# frozen_string_literal: true

class DownloadTicketFiles < Command
  @command = 'download-ticket-files'
  @label = 'Download files from ticket.'
  @description = 'Download files attached to ticket.'
  @flags = [
    {
      flag: 'ticket',
      label: 'Ticket id.',
      type: String,
      required: true
    }
  ]

  def action(opts)

    require './lib/jira'

    jira = Jira.new
    jira.download_attachments(opts[:ticket])
  end
end
