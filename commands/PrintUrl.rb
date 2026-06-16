# frozen_string_literal: true

# Need documentation.
class PrintUrl < Command
  @command = 'print-url'
  @label = 'Print URL.'
  @description = 'Print URL.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Identifier.',
      type: String,
      required: true
    }
  ]

  def initialize
    @http = authenticate
  end

  def action(opts)
    request = {
      path: "/api/v1/repository/search?digi_id=#{opts.identifier}"
    }

    resp = @http.get(request)
    raise 'Unable to search service.' unless resp.code == 200

    data = JSON.parse(resp.data)

    # type = data.resource.do_type || raise('Missing required do_type in resource')
    type = (data.resource&.do_type || data&.type) || raise('Missing required type in resource')

    # @experimental = ["true", "t", "1", "yes"].include?(opts.experimental.to_s.downcase)

    identifier = data.resource.digi_id || raise('Missing required digi_id in resource')

    if (identifier == opts.identifier)

      embedUrl = "#{$configuration['VIEWER_ENDPOINT']}/api/embed/#{identifier}"

      request_view = {
        path: "/api/embed/#{identifier}"
      }

      resp = @http.get(request_view)

      raise "Unable to find resource #{identifier}." unless resp.code == 200

      puts "#{embedUrl} - #{resp.message}"

    end

  end

  def authenticate
    http = NiceHttp.new($configuration['VIEWER_ENDPOINT'])
    request = {
      path: '/api/v0/import/user/login.json',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        'username': $configuration['VIEWER_USER'],
        'password': $configuration['VIEWER_PASS']
      }
    }
    resp = http.post(request)
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    http
  end

end
