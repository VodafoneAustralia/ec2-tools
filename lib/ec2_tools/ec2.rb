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

require 'timeout'
require 'net/ssh'
require 'net/scp'
require 'aws'
require 'ec2_tools/route53'

module EC2Tools
  module EC2

    EC2_SSH_USER = ENV['EC2_SSH_USER']
    EC2_SSH_KEY_PATH = ENV['EC2_SSH_KEY_PATH']
    SSH_OPTS = { :keys => [EC2_SSH_KEY_PATH], :keys_only => true, :paranoid => false }
    DEFAULT_INSTANCE_TYPE = "t1.micro"
    STATE_CODES = {
      :pending => [0],
      :running => [16],
      :stopped => [80],
      :not_terminated => [0, 16, 32, 64, 80],
      :any => [0, 16, 32, 48, 64, 80]
    }

    def self.ec2
      ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.ap-southeast-2.amazonaws.com')
    end

    def self.amis_by_name(name)
      ec2.images.tagged('Name').tagged_values(name)
    end

    def self.latest_ami_by_name(name)
      amis = amis_by_name(name).sort do |ami_a, ami_b|
        ami_a.tags.Timestamp <=> ami_b.tags.Timestamp
      end
      amis.last
    end
  
    def self.stale_amis_by_name(name)
      amis = amis_by_name(name).sort do |ami_a, ami_b|
        ami_a.tags.Timestamp <=> ami_b.tags.Timestamp
      end
      amis.take(amis.count - 1)
    end

    def self.launch_instance(key_pair, instance_type, security_groups, duration, ami_name, hostname)
      short_hostname = hostname.split('.').first

      ami = latest_ami_by_name(ami_name)
      if !ami
        puts "No such AMI with name #{ami_name}"
        exit 1
      end

      instance_opts = {
        :image_id => ami.id,
        :key_name => key_pair,
        :instance_type => instance_type,
        :block_device_mappings => { "/dev/sda1" => { :volume_size => 100 } },
        :security_groups => security_groups
      }

      if duration
        instance_opts[:instance_initiated_shutdown_behavior] = 'terminate'
      end

      puts "Launching instance with hostname #{hostname} from AMI #{ami.id}"

      instance = ec2.instances.create(instance_opts)

      puts "EC2 Instance ID: #{instance.id}"
      puts "Waiting for instance to transition to running state"

      begin
        wait_for_instance_state(instance, :running)
      rescue Timeout::Error
        puts "Timed out waiting for instance to transition to #{state} state"
        exit 1
      end

      puts "EC2 IP Address: #{instance.ip_address}"
      puts "EC2 Hostname: #{instance.dns_name}"

      begin
        name_instance(instance, hostname)
      rescue => exception
        puts exception.message
        exit 1
      end

      if duration
        puts "Waiting for port 22 to open on #{instance.dns_name}"
        begin
          EC2Tools::wait_for_port instance.dns_name, 22
        rescue Timeout::Error
          puts "Timed out waiting for port to open"
          exit 1
        end
    
        puts "Scheduling termination in #{duration} minutes"
        ssh_exec(instance, "echo 'sudo halt' | at now + #{duration} min")
      end
    end

    def self.wait_for_instance_state(instance, state, timeout = 120)
      Timeout::timeout(timeout) do
        while instance.status != state
          sleep 1
        end
      end
    end

    def self.name_instance(instance, hostname)
      puts "Marking duplicate tagged hosts as obsolete"
      named_instances = ec2.instances.tagged('Name').tagged_values(hostname)
      duplicate_instances = named_instances.reject { |other_instance| other_instance.id == instance.id }
      duplicate_instances.each do |duplicate_instance|
        duplicate_instance.tag('Name', :value => "#{duplicate_instance.tags.Name} (obsolete)")
      end

      puts "Tagging instance with Hostname: #{hostname}"
      instance.tag('Name', :value => hostname)

      #puts "Waiting for port 22 to open on #{instance.dns_name}"
      #EC2Tools::wait_for_port instance.dns_name, 22

      #puts "Setting instance's local hostname to #{hostname}"
      #dest = '/tmp/set_hostname.sh'
      #scp_exec(instance, File.expand_path('../../lib/set_hostname.sh', __FILE__), dest)
      #ssh_exec(instance, "chmod 755 #{dest}")
      #ssh_exec(instance, dest)
      
      EC2Tools::Route53::create_or_overwrite_rrset('CNAME', "#{hostname}.", instance.dns_name, false)
    end

    def self.list_instances(state_codes, pattern)
      state_codes = state_codes.map { |code| code.to_s }
      ec2.instances.filter('instance-state-code', state_codes).select do |instance|
        instance.tags.Name =~ pattern
      end
    end

    def self.ssh_exec(instance, command)
      Net::SSH.start(instance.dns_name, EC2_SSH_USER, SSH_OPTS) do |ssh|
        ssh.exec! command do |ssh, stream, data|
          puts data if stream == :stderr
        end
      end
    end
  
    def self.scp_exec(instance, source, dest)
      Net::SCP.start(instance.dns_name, EC2_SSH_USER, SSH_OPTS) do |scp|
        scp.upload! source, dest
      end
    end
 
  end
end
