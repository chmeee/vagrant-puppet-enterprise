# -*- mode: ruby -*-
# vi: set ft=ruby :

MASTERMEM=4096
NODEMEM=1024
LINNODES=%w{ centos/7 generic/debian9 }
WINNODES=%w{ opentable/win-2012r2-standard-amd64-nocm }

Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.vm.provider :libvirt do |domain|
    domain.management_network_address = "10.254.0.0/24"
    domain.management_network_name = "puppet"
  end

  config.vm.define 'util' do |device|
    device.vm.host_name = 'util'
    device.vm.box = 'centos/7'
    device.hostmanager.aliases = %w{ util.puppet git git.puppet }

    device.vm.synced_folder '.', '/vagrant', disabled: true
    device.vm.boot_timeout = 400

    device.vm.provider :libvirt do |v|
      v.memory = NODEMEM
      v.cpus = 1
    end

    device.vm.provision :shell, privileged: true, inline: <<-SHELL
    yum install -y docker
    systemctl enable docker
    systemctl start docker
    docker volume create gitea
    docker run -d --restart=always -e SSH_DOMAIN=util -p 3000:3000 -p 222:22 -v gitea:/data gitea/gitea 
    SHELL
  end

  config.vm.define 'puppet' do |device|
    device.vm.host_name = 'puppet'
    device.vm.box = "centos/7"
    device.hostmanager.aliases = %w(puppet.puppet puppet.home)


    device.vm.provider :libvirt do |v|
      v.memory = MASTERMEM
      v.cpus = 2
    end

    device.vm.synced_folder '.', '/vagrant', disabled: false
    device.vm.boot_timeout = 400

    device.vm.provision :shell, privileged: true, path: "./files/install-puppet-enterprise.sh"
    device.vm.provision :shell, privileged: true, inline: "/vagrant/files/add-debian-repo-to-pe-master.rb"

    # shameful kludge to avoid return code 2 from correct agent execution with changes to stop vagrant
    device.vm.provision :shell, privileged: true, inline: "/usr/local/bin/puppet agent -t; true" 
    device.vm.provision :shell, privileged: true, path: "./files/add-ssh-key.sh"
  end

  LINNODES.each_with_index do |node, i|
    name = "linux"
    config.vm.define name + "#{i+1}" do |device|
      device.vm.host_name = name + "#{i+1}"
      device.vm.box = node
      device.hostmanager.aliases = name + "#{i+1}.puppet" 

      device.vm.synced_folder '.', '/vagrant', disabled: true
      device.vm.boot_timeout = 400

      device.vm.provider :libvirt do |v|
        v.memory = NODEMEM
        v.cpus = 1
      end

      # shameful kludge to avoid return code 2 from correct agent execution with changes to stop vagrant
      device.vm.provision :file, source: "files/linux-csr_attributes.yaml", destination: "/tmp/csr_attributes.yaml"
      device.vm.provision :shell, privileged: true, inline: <<-SHELL
      curl -sLk https://puppet:8140/packages/current/install.bash | bash
      cp /tmp/csr_attributes.yaml /etc/puppetlabs/puppet/
      /usr/local/bin/puppet agent -t
      true
      SHELL
    end
  end

  WINNODES.each_with_index do |node, i|
    name = "win"
    config.vm.define name + "#{i+1}" do |device|
      device.vm.host_name = name + "#{i+1}"
      device.vm.box = node
      device.hostmanager.aliases = name + "#{i+1}.puppet" 

      config.vm.provider :libvirt do |domain|
        domain.nic_model_type = "rtl8139"
      end
      device.vm.communicator = "winrm"
      device.vm.synced_folder '.', '/vagrant', disabled: true

      device.vm.provision :shell, privileged: true, inline: <<-SHELL
      [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      (New-Object System.Net.WebClient).DownloadFile('https://puppet:8140/packages/current/install.ps1', '\\tmp\\install.ps1')
      \\tmp\\install.ps1
      SHELL
      device.vm.provision :file, source: "files/win-csr_attributes.yaml", destination: "/ProgramData/PuppetLabs/puppet/etc/csr_attributes.yaml"
      device.vm.provision "shell", privileged: true, inline: "'C:\Program Files\Puppetlabs\puppet\bin\puppet agent -t'"
    end
  end

end
