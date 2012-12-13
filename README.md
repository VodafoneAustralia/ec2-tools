# Summary

A bunch of wrapper scripts for the Amazon EC2 API command line tools, which are intended to support a simple workflow.

The basic idea is that you want to bring up one or more EC2 instances, tag each one with a FQDN and then configure Route53 DNS to point that name to the associated host.

Accordingly, most of the scripts work on the assumption that each of your EC2 instances has a tag called "Name", with the value being the FQDN of the host.

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

