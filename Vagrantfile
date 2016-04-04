# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/precise64"

  config.vm.define "new-server" do |ns|
    ns.vm.network "forwarded_port", guest: 80, host: 8080

    ns.vm.provision "shell", inline: <<-SHELL
        sudo apt-get install -y python-twisted-web
        mkdir -p /home/vagrant/leodis
        echo "<h1>Welcome to leodis.ac.uk!</h1>" > /home/vagrant/leodis/index.html
        twistd -no web -p 1337 --path=/home/vagrant/leodis/ &
    SHELL

    ns.vm.provision "ansible" do |ansible|
      ansible.groups = {
        'webservers' => ['new-server']
      }

      ansible.playbook = "./playbook/webservers.yml"
    end
  end

end
