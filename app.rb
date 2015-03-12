require 'aws-sdk'
require 'sinatra'
require 'net/http'
require 'json'

def auto_scaling
  @auto_scaling ||= Aws::AutoScaling::Client.new
end

def ec2
  @ec2 ||= Aws::EC2::Client.new
end

## return array of auto_scaling group structs
def auto_scaling_instances(group)
  auto_scaling.describe_auto_scaling_instances.map(&:auto_scaling_instances).flatten.select do |instance|
    instance.auto_scaling_group_name == group
  end
end

## query cadvisor on IP and return hash of data
def cadvisor_containers(ip)
  port = ENV.fetch('CADVISOR_PORT', 8080)
  http = Net::HTTP.new(ip, port)
  http.read_timeout = 5
  JSON.parse(http.get('/api/v1.2/docker/').body)
rescue => e
  logger.warn "#{ip} cadvisor: #{e.message}"
  [ ]
end

## return diff of two DateTime objects as human-readable string
def human_datetime_diff(t1, t2)
  diff = t1 - t2 # diff in days as a Rational
  mod = [ [:day, 1], [:hour, 24], [:minute, 24*60], [:second, 24*60*60] ].find do |m|
    diff * m[1] > 1
  end
  num = (diff * mod[1]).floor
  unit = mod[0].to_s + (num == 1 ? '' : 's') # unit in singular or plural
  "#{num} #{unit}"
end

## return bootstrap-compatible label flag for an instance state
def state_color(state)
  @states ||= { 'InService' => :success, 'Pending' => :warning, 'Terminating' => :warning, 'Terminated' => :danger }
  @states.fetch(state, :info)
end

## list all auto-scaling groups
get '/' do
  @groups = auto_scaling.describe_auto_scaling_groups.auto_scaling_groups
  @title = 'Auto-scaling groups'
  haml :index
end

## list instances and containers for this auto-scaling group
get '/:group' do
  @instances = Hash.new { |h, k| h[k] = {} }

  ## get instances for this auto_scaling group
  auto_scaling_instances(params[:group]).each do |instance|
    @instances[instance.instance_id][:auto_scaling] = instance
  end

  ## get ec2 details for instances
  unless @instances.empty?
    ec2.describe_instances(instance_ids: @instances.keys).map(&:reservations).flatten.map(&:instances).flatten.each do |instance|
      @instances[instance.instance_id][:ec2] = instance

      ## get containers from cadvisor
      @instances[instance.instance_id][:containers] = cadvisor_containers(instance.public_dns_name)
    end
  end

  @title = params[:group]
  haml :group
end
