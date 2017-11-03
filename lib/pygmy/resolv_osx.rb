require 'colorize'
require 'tempfile'
require 'pathname'

module Pygmy
  module ResolvOsx
    def self.resolver_dir
      Pathname("/etc/resolver")
    end

    def self.resolver_file
      "/etc/resolver/dev.topdroplabs.com"
    end

    def self.create_resolver?
      puts "setting up DNS resolution and loopback alias IP, this may require sudo".green
      unless self.resolver_dir.directory?
        self.system!("creating #{self.resolver_dir}", "sudo", "mkdir", "-p", self.resolver_dir)
      end
      Tempfile.open('amazeeio_pygmy-dnsmasq') do |f|
        f.write(self.resolver_contents)
        f.close
        self.system!("creating #{self.resolver_file}", "sudo", "cp", f.path, self.resolver_file)
        self.system!("creating #{self.resolver_file}", "sudo", "chmod", "644", self.resolver_file)
      end
      self.system!("creating loopback IP alias 172.16.172.16", "sudo", "ifconfig", "lo0", "alias", "172.16.172.16")
      self.system!("restarting mDNSResponder", "sudo", "killall", "mDNSResponder")
    end

    def self.clean?
      puts "Removing resolver file and loopback alias IP, this may require sudo".green
      begin
        self.system!("removing resolverfile", "sudo", "rm", "-f", self.resolver_file)
        self.system!("removing loopback IP alias 172.16.172.16", "sudo", "ifconfig", "lo0", "-alias", "172.16.172.16")
        system!("restarting mDNSResponder", "sudo", "killall", "mDNSResponder")
      rescue Exception => e
        puts e.message
      end
    end

    def self.system!(step, *args)
      system(*args.map(&:to_s)) || raise("Error with the #{name} daemon during #{step}")
    end

    def self.resolver_contents; <<-EOS.gsub(/^      /, '')
      # Generated by amazeeio pygmy
      nameserver 127.0.0.1
      port 53
      EOS
    end

    def self.resolver_file_contents
      File.read(self.resolver_file) unless !File.file?(self.resolver_file)
    end

    def self.resolver_file_exists?
      (self.resolver_file_contents == self.resolver_contents)
    end
  end
end
