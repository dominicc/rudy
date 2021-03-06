
library :rudy, 'lib'
group "Metadata"

tryout "Rudy::Machine Instance API" do
  
  set :test_domain, Rudy::DOMAIN #'test_' << Rudy::Utils.strand(4)
  set :test_env, 'stage' #'env_' << Rudy::Utils.strand(4)

  setup do
    Rudy.enable_debug
    Rudy::Huxtable.global.offline = true
    Rudy::Huxtable.update_config          # Read config files
    global = Rudy::Huxtable.global
    global.environment = test_env
    akey, skey, region = global.accesskey, global.secretkey, global.region
    Rudy::Metadata.connect akey, skey, region
    Rudy::AWS::EC2.connect akey, skey, region
  end
  
  clean do
    if Rudy.debug?
      puts $/, "Rudy Debugging:"
      Rudy::Huxtable.logger.rewind
      puts Rudy::Huxtable.logger.read unless Rudy::Huxtable.logger.closed_read?
    end
  end

  dream :instid, nil
  drill "machine instid is nil by default" do
    Rudy::Machine.new '02'
  end
  
  dream :nil?, false
  dream :class, String
  drill "create machine with instance" do
    mach = Rudy::Machine.new '02'
    mach.create
    mach.instid
  end
  
  dream :nil?, false
  drill "refresh machine" do
    mach = Rudy::Machine.new '02'
    mach.refresh!
    mach.instid
  end
  
  dream [true, true]
  drill "knows about the state of the instance" do
    mach = Rudy::Machine.new '02'
    mach.refresh!
    [mach.instance_exists?, mach.instance_running?]
  end
  
  dream true
  drill "destroy machine with instance" do
    mach = Rudy::Machine.new '02'
    mach.refresh!
    mach.destroy
  end
  
  
end