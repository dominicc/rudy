
module Rudy; module AWS
  module EC2
#    include Rudy::Huxtable
    
    def self.connect(access_key=nil, secret_key=nil, region=nil, logger=nil)

      if region
        raise InvalidRegion, region unless Rudy::AWS.valid_region?(region)
        host = "#{region}.ec2.amazonaws.com"
      elsif ENV['EC2_URL']
        host = URL.parse(ENV['EC2_URL']).host
      end
      
      host ||= DEFAULT_EC2_HOST
      port ||= DEFAULT_EC2_PORT
      
      @@ec2 = ::EC2::Base.new(:port => port, :server=> host, :access_key_id => access_key, :secret_access_key => secret_key)
      @@logger = logger
    end
    
  protected
  
    # Execute AWS requests safely. This will trap errors and return
    # a default value (if specified).
    # * +default+ A default response value
    # * +request+ A block which contains the AWS request
    # Returns the return value from the request is returned untouched
    # or the default value on error or if the request returned nil. 
    def self.execute_request(default=nil, timeout=nil, &request)
      timeout ||= 15
      raise "No block provided" unless request
      response = nil
      begin
        Timeout::timeout(timeout) do
          response = request.call
        end
      # Raise the EC2 exceptions
      rescue ::EC2::Error, ::EC2::InvalidInstanceIDMalformed => ex  
        raise Rudy::AWS::Error, ex.message
      
      # NOTE: The InternalError is returned for non-existent volume IDs. 
      # It's probably a bug so we're ignoring it -- Dave. 
      rescue ::EC2::InternalError => ex
        raise Rudy::AWS::Error, ex.message
        
      rescue Timeout::Error => ex
        STDERR.puts "Timeout (#{timeout}): #{ex.message}!"
      rescue SocketError => ex
        #STDERR.puts ex.message
        #STDERR.puts ex.backtrace
        raise SocketError, "Check your Internets!" unless @@global.offline
      ensure
        response ||= default
      end
      response
    end
    
    class NoRunningInstances < Rudy::Error; end
    class MalformedResponse < Rudy::Error; end
    class InvalidRegion < Rudy::Error; end
    class UnknownState < Rudy::Error; end
    class NoGroup < Rudy::Error; end
    class NoKeypair < Rudy::Error; end
    class NoAMI < Rudy::Error; end
    
    class NoAddress < Rudy::Error; end
    class UnknownAddress < Rudy::Error; end
    class NoInstanceID < Rudy::Error; end
    class AddressAssociated < Rudy::Error; end
    class ErrorCreatingAddress < Rudy::Error; end
    class AddressNotAssociated < Rudy::Error; end
    class InsecureKeypairPermissions < Rudy::Error; end
    
    class InsecureKeypairPermissions < Rudy::Error; end
    class ErrorCreatingKeypair < Rudy::Error; end
    class NoPrivateKeyFile < Rudy::Error; end
    class KeypairExists < Rudy::Error; end
    class KeypairAlreadyDefined < Rudy::Error
      def message
        "A keypair is defined for #{@obj}. Check your Rudy config."
      end
    end
    
    class VolumeAlreadyAttached < Rudy::Error; end
    class VolumeNotAvailable < Rudy::Error; end
    class VolumeNotAttached < Rudy::Error; end
    class UnknownVolume < Rudy::Error; end
    class NoInstanceID < Rudy::Error; end
    class NoVolumeID < Rudy::Error; end
    class UnknownState < Rudy::Error; end
    class NoDevice < Rudy::Error; end
    
    
  end
end; end