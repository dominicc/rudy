


module Rudy
  
  # = Rudy::Huxtable
  #
  # Huxtable gives access to instances for config, global, and logger to any
  # class that includes it.
  #
  #     class Rudy::Hello
  #       include Rudy::Huxtable
  #
  #       def print_config
  #         p self.config.defaults
  #       end
  #
  #     end
  #
  module Huxtable
    
    # TODO: investigate @@debug bug. When this is true, Caesars.debug? returns true
    # too. It's possible this is intentional but probably not. 
    @@debug = false
    
    @@config = Rudy::Config.new
    @@global = OpenStruct.new
    @@logger = StringIO.new    # BUG: memory-leak for long-running apps
    
    def config; @@config; end
    def global; @@global; end
    def logger; @@logger; end
    
    # Initializes config, global, and logger. Calls +init+ if present.
    #
    # +opts+ is a hash which expects any of the following keys:
    #
    # * +:config+ a path or an instance of Rudy::Config
    # * +:global+ a hash of global parameters
    # * +:logger+ an IO object or nil (default: STDERR)
    #
    # NOTE: These values are shared across all classes which include
    # Rudy::Huxtable. If anything has changed, the connections to AWS
    # will automatically reconnect. 
    # 
    def initialize(opts={})
      
      # TODO: Syncronize this code. Only a single thread should set this at a time.
      
      @@logger = opts[:logger] if opts[:logger].kind_of?(IO) || opts[:logger].kind_of?(StringIO)
      @@config = opts[:config] if opts[:config].is_a?(Rudy::Config)
      
      conf_path = opts[:global] ? opts[:global].config : nil
      
      self.init_config conf_path
      self.init_global opts[:global]
      
      String.disable_color if @@global.nocolor
      Rudy.enable_quiet if @@global.quiet
      
      raise Rudy::NoConfig unless has_keys?
      
      # Reconnect if anything has changed. 
      # I have a hunch this huxtable arrangement is going to haunt me.
      Rudy::AWS.reconnect if opts[:global] || opts[:config] || opts[:logger]
      
      self.init if self.respond_to? :init
    end
    
    def self.init_config(path=nil)
      # nil or otherwise bad paths send to look_and_load are ignored
      @@config.look_and_load(path || nil)
    end
    
    def self.init_global(ghash={})
      ghash = ghash.marshal_dump if ghash.is_a?(OpenStruct)
      
      ghash.each_pair { |n,v| @@global.send("#{n}=", v) } if ghash.is_a?(Hash)
      
      @@global.verbose ||= 0
      
      @@global.cert = File.expand_path(@@global.cert || '')
      @@global.privatekey = File.expand_path(@@global.privatekey || '')
      
      # ATROCIOUS!
      
      if @@config.defaults?
        @@global.region ||= @@config.defaults.region
        @@global.zone ||= @@config.defaults.zone
        @@global.environment ||= @@config.defaults.environment
        @@global.role ||= @@config.defaults.role 
        @@global.position ||= @@config.defaults.position
        @@global.user ||= @@config.defaults.user 
        @@global.nocolor = @@config.defaults.nocolor
        @@global.quiet = @@config.defaults.quiet
      end
            
      @@global.region ||= DEFAULT_REGION
      @@global.zone ||= DEFAULT_ZONE
      @@global.environment ||= DEFAULT_ENVIRONMENT
      @@global.role ||= DEFAULT_ROLE
      @@global.position ||= DEFAULT_POSITION
      @@global.user ||= DEFAULT_USER
      @@global.nocolor = false
      @@global.quiet = false
      
      @@global.position &&= @@global.position.to_s.rjust(2, '0')
      
      if @@config.accounts? && @@config.accounts.aws
        @@global.accesskey ||= @@config.accounts.aws.accesskey 
        @@global.secretkey ||= @@config.accounts.aws.secretkey 
        @@global.account ||= @@config.accounts.aws.accountnum
        
        @@global.cert ||= @@config.accounts.aws.cert
        @@global.privatekey ||= @@config.accounts.aws.privatekey
      end
      
      @@global.accesskey ||= ENV['AWS_ACCESS_KEY']
      @@global.secretkey ||= ENV['AWS_SECRET_KEY'] || ENV['AWS_SECRET_ACCESS_KEY']
      @@global.account ||= ENV['AWS_ACCOUNT_NUMBER']
      
      @@global.cert ||= ENV['EC2_CERT']
      @@global.privatekey ||= ENV['EC2_PRIVATE_KEY']
      
      @@global.local_user = ENV['USER'] || :rudy
      @@global.local_hostname = Socket.gethostname || :localhost
      

    end
    
    def init_config(path=nil); Rudy::Huxtable.init_config(path); end
    def init_global(path=nil); Rudy::Huxtable.init_global(path); end
    
    # This will setup the config and global class variables until
    # otherwise specified. init_config must come before init_global.
    init_config
    init_global
        
    def debug?; @@debug == true; end
    
    def check_keys
      raise "No EC2 .pem keys provided" unless has_pem_keys?
      raise "No SSH key provided for #{current_user}!" unless has_keypair?
      raise "No SSH key provided for root!" unless has_keypair?(:root)
    end
      
    def has_pem_keys?
      (@@global.cert       && File.exists?(@@global.cert) && 
       @@global.privatekey && File.exists?(@@global.privatekey))
    end
     
    def has_keys?
      (@@global.accesskey && !@@global.accesskey.empty? && @@global.secretkey && !@@global.secretkey.empty?)
    end
    
    def config_dirname
      raise "No config paths defined" unless @@config.is_a?(Rudy::Config) && @@config.paths.is_a?(Array)
      base_dir = File.dirname @@config.paths.first
      raise "Config directory doesn't exist #{base_dir}" unless File.exists?(base_dir)
      base_dir
    end
    
    def has_keypair?(name=nil)
      kp = user_keypairpath(name)
      (!kp.nil? && File.exists?(kp))
    end
    
    def user_keypairname(user)
      kp = user_keypairpath(user)
      return unless kp
      KeyPairs.path_to_name(kp)
    end
    

    
    def user_keypairpath(name)
      raise "No user provided" unless name
      zon, env, rol = @@global.zone, @@global.environment, @@global.role
      #Caesars.enable_debug
      kp = @@config.machines.find_deferred(zon, env, rol, [:users, name, :keypair])
      kp ||= @@config.machines.find_deferred(env, rol, [:users, name, :keypair])
      kp ||= @@config.machines.find_deferred(rol, [:users, name, :keypair])
      
      # EC2 Keypairs that were created are intended for starting the machine instances. 
      # These are used as the root SSH keys. If we can find a user defined key, we'll 
      # check the config path for a generated one. 
      if !kp && name.to_s == 'root'
        path = File.join(self.config_dirname, "key-#{current_machine_group}")
        kp = path if File.exists?(path)
      end
      
      kp &&= File.expand_path(kp)
      kp
    end

    def has_root_keypair?
      path = user_keypairpath(:root)
      (!path.nil? && !path.empty?)
    end
    
    def current_user
      @@global.user
    end
    def current_user_keypairpath
      user_keypairpath(current_user)
    end
    def current_machine_hostname(group=nil)
      group ||= machine_group
      find_machine(group)[:dns_name]
    end
    
    def current_machine_group
      [@@global.environment, @@global.role].join(Rudy::DELIM)
    end
    
    def current_machine_image
      zon, env, rol = @@global.zone, @@global.environment, @@global.role
      ami = @@config.machines.find_deferred(zon, env, rol, :ami)
      ami ||= @@config.machines.find_deferred(env, rol, :ami)
      ami ||= @@config.machines.find_deferred(rol, :ami)
      raise Rudy::NoMachineImage, current_machine_group unless ami
      ami
    end
    
    def current_machine_address
      @@config.machines.find_deferred(@@global.environment, @@global.role, :address)
    end
    
    # TODO: fix machine_group to include zone
    def current_machine_name
      [@@global.zone, current_machine_group, @@global.position].join(Rudy::DELIM)
    end

    

    # +name+ the name of the remote user to use for the remainder of the command
    # (or until switched again). If no name is provided, the user will be revert
    # to whatever it was before the previous switch. 
    # TODO: deprecate
    def switch_user(name=nil)
      if name == nil && @switch_user_previous
        @@global.user = @switch_user_previous
      elsif @@global.user != name
        raise "No root keypair defined for #{name}!" unless has_keypair?(name)
        @@logger.puts "Remote commands will be run as #{name} user"
        @switch_user_previous = @@global.user
        @@global.user = name
      end
    end
    
    def group_metadata(env=@@global.environment, role=@@global.role)
      query = "['environment' = '#{env}'] intersection ['role' = '#{role}']"
      @sdb.query_with_attributes(Rudy::DOMAIN, query)
    end
    
    # * +opts+
    # :recursive => false, :preserve => false, :chunk_size => 16384
    def scp(task, host, user, keypairpath, paths, dest, opts)
      opts = { 
        :recursive => false, :preserve => false, :chunk_size => 16384
      }.merge(opts)
      
      Net::SCP.start(host, user, :keys => [keypairpath]) do |scp|
        paths.each do |path| 
          prev_path = nil
          scp.send("#{task}!", path, dest, opts) do |ch, name, sent, total|
            msg = ((prev_path == name) ? "\r" : "\n") # new line for new file
            msg << "#{name}: #{sent}/#{total}"  # otherwise, update the same line
            @@logger.print msg
            @@logger.flush        # update the screen every cycle
            prev_path = name
          end
          @@logger.puts unless prev_path == path
        end
      end
    end
    
    
  private 
    
  end
end

__END__
      
      # An instance of Rye::Box for the local machine (running Rudy)
      @@rbox = Rye::Box.new('localhost')