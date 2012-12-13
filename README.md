# Summary

A simple hostname-centric scripting interface to Amazon EC2.

Mostly wrapping the Amazon EC2 API command line tools, these scripts support a simple workflow for managing EC2 instances by hostname.  They're intended primarily for automation of EC2 from build systems, but can be used by fleshy beings as well.

The basic idea is that you want to bring up one or more EC2 instances, tag each one with a fully qualified hostname and then configure Route53 DNS to point that name to the associated host.

Accordingly, most of the scripts work on the assumption that each of your EC2 instances has a tag called "Name", with the value being the fully qualified hostname.

# System Requirements

* The Amazon EC2 API Tools: http://aws.amazon.com/developertools/351
* Java 1.6 or later (required by the EC2 API tools)
* Ruby 1.9.3 or later with HTTParty

# Environment Variables

Amazon identifiers and credentials are expected to be set in the environment.  Here's an example:


    # Path to your EC2 API Tools installation
    export EC2_HOME=~/ec2-api-tools-1.6.4
    export PATH=$PATH:$EC2_HOME/bin
  
    # Your AWS access Key
    export AWS_ACCESS_KEY=AAFAYUHUIQWHHFHE
  
    # Your AWS secret key
    export AWS_SECRET_KEY=rdS34$dy56uf^7iHhuif56D65uDU^5yuiIjo;Mnu67
  
    # The URL of the EC2 API endpoint in your region
    export EC2_URL=https://ec2.us-west-1.amazonaws.com
  
    # The zone id of the Route 53 zone you wish to contain your DNS records
    export ROUTE53_ZONE_ID=Z23IUQGHOUIOWGH
  
    # The name of the Route 53 zone you wish to contain your DNS records, e.g. example.com
    export ROUTE53_ZONE_NAME=example.com

# License

Copyright (c) 2012 DiUS Computing Pty Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

