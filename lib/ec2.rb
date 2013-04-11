# Copyright (c) 2012 DiUS Computing Pty Ltd

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial 
# portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

require 'socket'
require 'timeout'
require 'net/ssh'
require 'aws'

AWS_ACCESS_KEY = ENV['AWS_ACCESS_KEY']
AWS_SECRET_KEY = ENV['AWS_SECRET_KEY']
EC2_SSH_USER = ENV['EC2_SSH_USER']
EC2_SSH_KEY_PATH = ENV['EC2_SSH_KEY_PATH']

AWS.config(:access_key_id => AWS_ACCESS_KEY, :secret_access_key => AWS_SECRET_KEY)

def ec2
  ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.ap-southeast-2.amazonaws.com')
end

def amis_by_name(name)
  ec2.images.tagged('Name').tagged_values(name)
end

def latest_ami_by_name(name)
  amis = amis_by_name(name).sort do |ami_a, ami_b|
    ami_a.tags.Timestamp <=> ami_b.tags.Timestamp
  end
  amis.last
end
  
def stale_amis_by_name(name)
  amis = amis_by_name(name).sort do |ami_a, ami_b|
    ami_a.tags.Timestamp <=> ami_b.tags.Timestamp
  end
  amis.take(amis.count - 1)
end

def wait_for_instance_state(instance, state, timeout = 120)
  Timeout::timeout(timeout) do
    while instance.status != state
      sleep 1
    end
  end
end

def name_instance(instance, hostname)
  ec2_name_cmd = File.expand_path("../../bin/ec2-name", __FILE__)
  output, status = Open3.capture2e("#{ec2_name_cmd} -d #{instance.id} #{hostname}")
  puts output
  if status != 0
    raise "Error occurred trying to set name of instance #{instance.id}"
  end
end

def wait_for_port(ip_address, port, seconds = 120)
  Timeout::timeout(seconds) do
    open = false
    while !open
      sleep 1
      open = connect_to_port(ip_address, port)
    end
  end
end

def connect_to_port(ip_address, port)
  begin
    TCPSocket.new(ip_address, port).close
    true
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    false
  end
end

def ssh_exec(instance, command)
  ssh_opts = { :keys => [EC2_SSH_KEY_PATH], :keys_only => true, :paranoid => false }
  Net::SSH.start(instance.dns_name, EC2_SSH_USER, ssh_opts) do |ssh|
    ssh.exec! command do |ssh, stream, data|
      puts data if stream == :stderr
    end
  end
end
