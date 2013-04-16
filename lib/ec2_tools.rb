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
require 'aws'

require 'ec2_tools/ec2'
require 'ec2_tools/route53'

module EC2Tools

  AWS_ACCESS_KEY = ENV['AWS_ACCESS_KEY']
  AWS_SECRET_KEY = ENV['AWS_SECRET_KEY']

  AWS.config(:access_key_id => AWS_ACCESS_KEY, :secret_access_key => AWS_SECRET_KEY)

  def self.ec2
    ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.ap-southeast-2.amazonaws.com')
  end

  def self.wait_for_port(ip_address, port, seconds = 120)
    Timeout::timeout(seconds) do
      open = false
      while !open
        sleep 1
        open = connect_to_port(ip_address, port)
      end
    end
  end

  def self.connect_to_port(ip_address, port)
    begin
      TCPSocket.new(ip_address, port).close
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      false
    end
  end

end

