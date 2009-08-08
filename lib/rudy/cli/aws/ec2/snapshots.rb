

module Rudy; module CLI; 
module AWS; module EC2;
  
  class Snapshots < Rudy::CLI::CommandBase
    
    def create_snapshots_valid?
      raise Drydock::ArgError.new('volume ID', @alias) unless @option.volume
      @volume = Rudy::AWS::EC2::Volumes.get(@argv.volid)
      raise "Volume #{@volume.awsid} does not exist" unless @volume
      true
    end
    def create_snapshots
      snap = execute_action { Rudy::AWS::EC2::Snapshots.create(@volume.awsid) }
      puts @@global.verbose > 0 ? snap.inspect : snap.dump(@@global.format)
    end
    
    def destroy_snapshots_valid?
      raise Drydock::ArgError.new('snapshot ID', @alias) unless @argv.snapid
      @snap = Rudy::AWS::EC2::Snapshots.get(@argv.snapid)
      raise "Snapshot #{@snap.awsid} does not exist" unless @snap
      true
    end
    def destroy_snapshots
      puts "Destroying: #{@snap.awsid}"
      execute_check(:medium)
      execute_action { Rudy::AWS::EC2::Snapshots.destroy(@snap.awsid) }
      snapshots
    end
    
    def snapshots
      snaps = Rudy::AWS::EC2::Snapshots.list || []
      snaps.each do |snap|
        puts @@global.verbose > 0 ? snap.inspect : snap.dump(@@global.format)
      end
      puts "No snapshots" if snaps.empty?
    end
    
    
  end


end; end
end; end