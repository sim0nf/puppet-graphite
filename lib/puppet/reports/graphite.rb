require 'puppet'
require 'yaml'
require 'socket'
require 'time'

Puppet::Reports.register_report(:graphite) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "graphite.yaml"])
  raise(Puppet::ParseError, "Graphite report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  GRAPHITE_SERVER = config[:graphite_server]
  GRAPHITE_PORT = config[:graphite_port]

  desc <<-DESC
  Send notification of failed reports to a Graphite server via socket.
  DESC

  def send_metric payload
    socket = TCPSocket.new(GRAPHITE_SERVER, GRAPHITE_PORT)
    socket.puts payload
    socket.close
  end

  def process
    Puppet.debug "Sending status for #{self.host} to Graphite server at #{GRAPHITE_SERVER}"
    prefix = "puppet.#{self.host}"
    epochtime = Time.now.utc.to_i
    self.metrics.each { |metric,data|
      data.values.each { |val| 
        name = "#{prefix}.#{val[1]}_#{metric}"
        name.gsub!(/ /, '_')
        value = val[2]

        send_metric "#{name} #{value} #{epochtime}"
      }
    }
  end
end
