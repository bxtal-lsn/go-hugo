# Multipass Guide
Multipass is a lightweight VM manager developed by Canonical that enables quick creation and management of Ubuntu virtual machines on Linux, macOS, and Windows.  
It provides a simple CLI for launching, stopping, and managing instances with minimal configuration.  
Multipass uses native hypervisor technologies (HyperKit on macOS, Hyper-V on Windows, and KVM on Linux) for optimal performance.  
VMs are preconfigured with cloud-init for customization, include SSH access by default, and support mounting directories from the host system.  
Multipass targets developers needing isolated Ubuntu environments for testing and development without complex virtualization setups.  
It offers efficient resource management with minimal overhead compared to full VM solutions, making it particularly useful for local Kubernetes development, CI/CD testing, and cross-platform Ubuntu-based development workflows.

## Prerequisites
Install `snapd`. Install on Ubuntu by default

## Installation
To install run
```bash
snap install multipass
```
confirm that Multipass is installed
```bash
multipass
```
Make sure you’re part of the group that Multipass gives write access to its socket (sudo in this case, but it may also be wheel or admin, depending on your distribution).

Run this command to check which group is used by the Multipass socket:

```bash
ls -l /var/snap/multipass/common/multipass_socket
```
The output will be similar to the following:

```bash
srw-rw---- 1 root sudo 0 Dec 19 09:47 /var/snap/multipass/common/multipass_socket
```
Run the groups command to make sure you are a member of that group (in our example, “sudo”):

```bash
groups | grep sudo
```
The output will be similar to the following:
```bash
adm cdrom sudo dip plugdev lpadmin
```

You can view more information on the snap package using the snap info command:
```bash
snap info multipass
```
## Uninstall
```bash
snap remove multipass
```

## Basic Commands

- Spin up VMs
```bash
multipass launch --name machine1
multipass launch --name machine2
```
- list VMs and status/IPs
```bash
multipass list
```
- stop VM
```bash
multipass stop machine1
multipass stop machine2
```
- start VM
```bash
multipass start machine1 machine2
```
- shell into VM
```bash
multipass shell machine1
```
- ping other VMs
```bash
multipass ping machine2
```
- delte instance
```bash
multipass delete machine1
multipass delete machine2
```

- purge deleted instances
```bash
multipass purge
```
## Initial Provision of Ubuntu VMs
If some VMs need some standard settings and software when launched, use cloud init.

Create a file like something like this
```bash
vim cloudinit.yaml
```
Example of provisioning docker, insert this into the file
```bash
#cloud-config
package_update: true
packages:
  - docker.io
runcmd:
  # Enable and start the Docker service
  - systemctl enable docker
  - systemctl start docker
  # (Optional) Add the default user to the docker group
  - usermod -aG docker ubuntu
```

to initialize an instance use
```bash
multipass launch --name registry-master --cloud-init cloudinit.yaml
```

