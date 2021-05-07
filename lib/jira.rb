# frozen_string_literal: true

require 'nice_http'
require 'json'

# @todo Undocumented Class
class Jira
  def initialize
    @http = authenticate
  end

  def download_attachments(ticket_id)
    ticket = get("/rest/api/2/issue/#{ticket_id}")
    ticket.fields.attachment.each do |attachment|
      uri = URI(attachment.content)
      @http.get(uri.path, save_data: "#{$configuration['JOBS_DIR']}/#{ticket_id}-#{attachment.filename}")
      puts "Downloading attachment #{attachment.content}"
    end
  end

  def get(path)
    request = @http.get(path)
    res = JSON.parse(request.data)
    raise res.error if res.key?('error')

    res
  end

  def post(object)
    request = @http.post(
      path: '/api/v1/objects',
      headers: {
        'Content-Type': 'application/json'
      },
      data: object
    )
    res = JSON.parse(request.data)
    raise res.error if res.key?('error')

    puts res.data.to_json
  end

  def authenticate
    http = NiceHttp.new($configuration['TICKET_ENDPOINT'])
    http.headers.authorization = NiceHttpUtils.basic_authentication(user: $configuration['TICKET_USER'], password: $configuration['TICKET_PASS'])
    http
  end
end
