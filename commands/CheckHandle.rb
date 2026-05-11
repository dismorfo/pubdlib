# frozen_string_literal: true

# Need documentation.
class CheckHandle < Command
  @command = 'check-handle'
  @label = 'Check handle.'
  @description = 'Check handle.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Identifier.',
      type: String
    },
  ]

  def action(opts)
    require 'nice_http'
    require 'json'
    require './lib/se'
    require './lib/handle'

    entity = search_se_by_id(opts.identifier)

    abort unless entity
    if entity
      puts "Found SE with identifier #{opts.identifier} and type #{entity['resource']['do_type']}."
      fids = entity['resource']['fids']
      citation_url = fids['citation_url'] if fids && fids['citation_url']
      test_handle citation_url
    else
      puts "Unable to find SE with identifier #{opts.identifier}."
    end

  end

  private

  def search_se_by_id(identifier)
    http = NiceHttp.new($configuration['SE_ENDPOINT'])

    resp = http.post(
      {
        path: '/api/v0/import/user/login.json',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        data: {
          'username': $configuration['SE_USER'],
          'password': $configuration['SE_PASS']
        }
      }
    )
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    resp = http.get({ path: "/api/v1/repository/search?digi_id=#{identifier}" })
    raise "Unable to find resource #{identifier} in search service." unless resp.code == 200

    JSON.parse(resp.data)
  end

def test_handle(url)
  http = NiceHttp.new(url)
  http.auto_redirect = false

  # v1.8.9 requires a single Hash argument if headers are present
  resp = http.get({path: "", headers: { "Accept" => "application/json" }})

  # status is stored in :code, but headers are often in :header or directly in the hash
  status = resp[:code].to_s

  if status == "302" || status == "301"
    # Try the two places NiceHTTP v1 stores the location
    target = resp[:header].is_a?(Hash) ? resp[:header][:location] : resp[:location]
    
    puts "Redirecting to: #{target}"

    if target
      http_final = NiceHttp.new(target)
      resp_final = http_final.get("")
      puts "Final Destination Status: #{resp_final[:code]}"
    end
  else
    puts "Status: #{status}"
  end
end

end
