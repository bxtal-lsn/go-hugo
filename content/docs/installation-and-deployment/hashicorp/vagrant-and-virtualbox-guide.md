# Vagrant and VirtualBox Guide
Vagrant and VirtualBox combined provide a powerful infrastructure-as-code solution for development environments.  
Vagrant sits on top of VirtualBox, providing a CLI and workflow for creating, configuring, and managing virtual machines defined in code.  
Using them together enables infrastructure as code through Vagrantfiles written in Ruby syntax, creating reproducible environments that can be shared across team members.  
While VirtualBox is the common provider, Vagrant supports others like VMware and AWS.  
The combination facilitates automatic VM provisioning via shell scripts or configuration management tools like Ansible, simplifies network configuration for port forwarding and private networks, and enables seamless code syncing between host and guest machines through shared folders.  
Vagrant's simple commands (up/halt/destroy/ssh) manage the VM lifecycle, while pre-built "boxes" serve as base images that can be versioned and shared.  
Together, they enable developers to quickly spin up consistent environments without manual VirtualBox configuration, effectively addressing the "works on my machine" problem.  

## Installation
On Arch Linux Install Vagrant and VirtualBox with 
```bash
sudo pacman -S vagrant virtualbox
```

Set VirtualBox as default provider for Vagrant. 
Set this system wide in .bashrc  

Edit bashrc `vim ~/.bashrc`

Insert to bashrc export `VAGRANT_DEFAULT_PROVIDER=virtualbox`

Then source the bashrc `source ~/.bashrc`

The system needs to restart before VirtualBox is able to run

## VirtualBox Plugins
`VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant plugin install vagrant-cachier`
`VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant plugin install vagrant-hosts`
`VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant plugin install vagrant-ansible`


## Get Linux Images
vagrant boxes are available at `https://portal.cloud.hashicorp.com/vagrant/discover`  

To grab a oracle linux image, use `vagrant init generic/oracle9`

## Ansible Provisioning
In the vagrant directory run
```bash
mkdir -p ansible
touch ansible/provision.yml
```



