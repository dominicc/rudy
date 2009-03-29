

require 'ec2'
require 'aws_sdb'

module Rudy
  module AWS
        
    module ObjectBase
      attr_accessor :aws
      def initialize(aws_connection)
        @aws = aws_connection
      end
    end
  
    # TODO: Move to Rudy
    
    def self.instance_id?(id=nil)
      (id && id[0,2] == "i-")  # OR: split at dash, use first value
    end
    
    def self.image_id?(id=nil)
      (id && id[0,4] == "ami-")
    end
    
    def self.volume_id?(id=nil)
      (id && id[0,4] == "vol-")
    end
    
    def self.snapshot_id?(id=nil)
      (id && id[0,5] == "snap-")
    end



  
    class S3
      @@logger = StringIO.new

      attr_reader :aws

      def initialize(access_key, secret_key)
       # @aws = RightAws::S3.new(access_key, secret_key, {:logger => Logger.new(@@logger)})
      end
    end
    
    class SimpleDB
      @@logger = StringIO.new
    
      attr_reader :domains
      attr_reader :aws
    
      def initialize(access_key, secret_key)
        @aws = AwsSdb::Service.new(:access_key_id => access_key, :secret_access_key => secret_key, :logger => Logger.new(@@logger))
        @domains = Rudy::AWS::SimpleDB::Domains.new(@aws)
      end

    end
    
    require 'rudy/aws/simpledb'
    require 'rudy/aws/ec2'
    require 'rudy/aws/s3'
    
  end
  
end

# Require EC2, S3, Simple DB class
begin
  # TODO: Use autoload
  Dir.glob(File.join(RUDY_LIB, 'rudy', 'aws', '{ec2,s3,sdb}', "*.rb")).each do |path|
    require path
  end
rescue LoadError => ex
  puts "Error: #{ex.message}"
  exit 1
end

