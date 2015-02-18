#
# Vagrant Configuration Class
#
# Freely inspired from "Laravel Homestead"
#
# @author   Akarun for KRKN <akarun@krkn.be> and Passtech <akarun@passtech.be>
# @since    Jan 2014
#
#  ============================================================================

require 'socket'
require 'json'
require 'yaml'

# -----------------------------------------------------------------------------
class VagrantConfig
    
    attr_accessor :config, :name, :host

    #
    # Constructor
    #
    def initialize(config)
        @config = config
        @name = ""
        @host = ""
    end

    # -------------------------------------------------------------------------

    #
    # Load configuration filea
    #
    def loadConfig(configPath=nil)
        if !configPath.nil? && File.exists?(configPath)

            if File.extname(configPath) == '.json'
                self.configure JSON::parse(File.read(configPath))

            elsif File.extname(configPath) == '.yaml'
                self.configure YAML::load(File.read(configPath))

            end
        end
    end

    # -------------------------------------------------------------------------

    def loadProvision(provisionPath=nil)

        if provisionPath.nil?
            return false
        
        elsif provisionPath.kind_of? String
            provisionPath = [provisionPath]

        end

        provisionPath.each do |provision|
            if File.exists?(provision)
                @config.vm.provision :shell, :path => provision, :args => [@name, @hostname], :keep_color => true
                
            end
        end
    end

    # -------------------------------------------------------------------------

    #
    # Configure the box
    #
    def configure(settings = {})
        @hostname = settings["host"] ||= "vagrantkrkn"
        @name = ( settings["name"] ||= @hostname.sub(/^(\w)/) {|s| s.capitalize} )

        @config.vm.hostname = @hostname
        @config.vm.box = settings["box_name"] ||= "wheezy64"
        @config.vm.box_url = settings["box_url"] ||= "http://vagrant.krkn.be/debian-wheezy64.box"
        
        # Configure A Private Network IP
        if settings.has_key?('private_ip')
            @config.vm.network :private_network, ip: settings["private_ip"] ||= "192.168.10.10"
        end

        # Configure A Public Network
        if settings.has_key?('public_ip')
            bridge = self.getBridgeInterface( settings["public_interfaces"] )
            public_ip = settings['public_ip']

            if public_ip.kind_of? String
                if ['dhcp', 'auto'].include? public_ip.downcase
                    @config.vm.network "public_network", bridge: bridge[1]
                else
                    @config.vm.network "public_network", bridge: bridge[1], ip: public_ip
                end
                
            else
                @config.vm.network "public_network", bridge: bridge[1], ip: self.getMachineIp(200, bridge[0])
            
            end
        end

        # Shared folders (by Default)
        config.vm.synced_folder ".", "/vagrant",
            owner: "vagrant",
            group: "www-data",
            mount_options: ["dmode=775,fmode=664"]

        # Provision from config
        if settings.has_key?('provision')
            self.loadProvision(settings['provision'])
        end

        # Configure A Few VirtualBox Settings
        @config.vm.provider "virtualbox" do |vb|
            vb.name = @name 

            vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
            vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
            vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            
            vb.gui = settings["gui"] ||= false
        end

        # Some port forwarding
        config.vm.network "forwarded_port", guest: 3306, host: 33060
        config.vm.network "forwarded_port", guest: 5432, host: 54320
    end

    # -------------------------------------------------------------------------

    #
    # Construct Vagrant IP based on Host IP.
    #
    def getMachineIp( new_num=250, base_ip=nil )
        unless base_ip.nil?
            base_ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
        end

        unless base_ip.nil?
            base_ip.ip_address.split('.').tap{|i| i[-1] = Integer(new_num) }.join('.')
        end
    end

    # -------------------------------------------------------------------------

    #
    # Detect the Bridged interface (to avoid Vagrant ask for it).
    #
    def getBridgeInterface( pref_interface = nil )
        vm_interfaces = %x( VBoxManage list bridgedifs | egrep "^(Name|IPAddress)" )
            .gsub(/(Name:\s+)(.*)\n(IPAddress:\s+)(.*)\n/, "\\4#\\2\n")
            .split("\n")
            .map {|n| n if n[/([0-9.]*)/] != '0.0.0.0' }
            .compact
            .map {|n| n.split("#")}

        unless pref_interface.nil?
            if (pref_interface.kind_of? String) then pref_interface = [pref_interface] end
            pref_bridge = (vm_interfaces.map {|n| n if pref_interface.include?(n[1])}.compact)[0]

            unless pref_bridge.nil?
                return pref_bridge
            end
        end

        vm_interfaces[0]
    end
end