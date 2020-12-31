#! /usr/bin/env ruby
#
#   check-mesos
#
# DESCRIPTION:
#   This plugin checks that the health url returns 200 OK
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2015, Tom Stockton (tom@stocktons.org.uk)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'

class MesosNodeStatus < Sensu::Plugin::Check::CLI
  option :server,
         description: 'Mesos servers, comma separated',
         short: '-s SERVER1,SERVER2,...',
         long: '--server SERVER1,SERVER2,...',
         default: 'localhost'

  option :port,
         description: 'port (default 5050, use 5051 for slaves)',
         short: '-p PORT',
         long: '--port PORT',
         default: 5050,
         required: false

  option :protocol,
         description: 'Marathon protocol [http/https]',
         short: '-P PROTOCOL',
         long: '--protocol PROTOCOL',
         required: false,
         default: 'http'

  option :uri,
         description: 'Endpoint URI',
         short: '-u URI',
         long: '--uri URI',
         default: '/health'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  def run
    servers = config[:server]
    uri = config[:uri]
    port = config[:port]
    failures = []
    servers.split(',').each do |server|
      begin
        r = RestClient::Resource.new("#{config[:protocol]}://#{server}:#{port}#{uri}", timeout: config[:timeout]).get
        if r.code != 200
          failures << "Mesos on #{server} is not responding"
        end
      rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
        failures << "Mesos on #{server} is not responding"
      rescue RestClient::RequestTimeout
        failures << "Mesos on #{server} connection timed out"
      end
    end
    if failures.empty?
      ok "Mesos is running on #{servers}"
    else
      critical failures.join("\n")
    end
  end
end
