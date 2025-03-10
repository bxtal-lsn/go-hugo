## Installation
See installation operions on [ansible installation](https://docs.ansible.com/ansible/latest/installation_guide/index.html)

For Arch Linux run `sudo pacman -S ansible`
To confirm run `ansible --version`
Encounter error with `/etc/ansible/ansible.cfg` where the syntax is invalid.
Delete everything in file proved to work?

## Overview
1. **Inventory**  
**Definition**: A file that lists the target machines Ansible will manage.  
**Formats**: Can be static (YAML or INI) or dynamic (using plugins or scripts to fetch hosts from cloud providers).  
**Purpose**: Organizes hosts into groups and defines connection details and variables for each host.  

2. **Modules**  
**Definition**: Predefined units of work (scripts) that Ansible executes on target machines.  
**Types**:
   - **Core Modules**: Built into Ansible (e.g., file, copy, package).  
   - **Custom Modules**: User-defined for specific needs.  
**Purpose**: Perform actions like file manipulation, package installation, and service management.  

3. **Playbooks**  
**Definition**: YAML files that define a series of tasks to be executed on hosts.  
**Purpose**: Act as the blueprint for automation, describing what actions to take and in what order.  
**Structure**:
    - Hosts (targets for execution).  
    - Tasks (actions performed using modules).  
    - Variables (customizable data).  

4. **Tasks**   
**Definition**: Individual actions defined in a playbook, executed sequentially.
**Purpose**: Represent atomic units of work, such as installing a package or restarting a service.

5. **Roles** 
**Definition**: A way to organize playbooks, tasks, variables, files, and templates into reusable components.
**Purpose**: Enable code reuse, modular design, and simplified playbook management.

6. **Variables** 
**Definition**: Key-value pairs used to customize playbooks and tasks.
**Purpose**: Allow dynamic configuration and adaptation based on the environment or host.

7. **Templates**
**Definition**: Files (usually written in Jinja2) with placeholders for variables.
**Purpose**: Generate configuration files or scripts dynamically during execution.

8. **Plugins**  
**Definition**: Specialized code used to extend Ansible’s functionality.  
**Types**:  
    - **Connection Plugins**: Handle communication with target machines.  
    - **Lookup Plugins**: Retrieve data from external sources.  
    - **Filter Plugins**: Manipulate variables or data.  
**Purpose****: Enhance flexibility and enable advanced use cases.  

9. **Handlers**   
**Definition**: Tasks triggered only when a change is detected.
**Purpose**: Ensure certain actions, like restarting a service, occur only when necessary.

10. **Facts** 
**Definition**: System information gathered by Ansible from the target machine (e.g., OS, IP, memory).
**Purpose**: Enable conditional logic in playbooks based on the host’s environment.

11. **Ansible Command-Line Tools**
**Examples**:
**ansible**: Run ad-hoc commands on target machines.
**ansible-playbook**: Execute playbooks.
**ansible-galaxy**: Manage roles and collections.
**Purpose**: Facilitate task execution, debugging, and management.

## Inventory
### Purpose
An Ansible inventory file is a key component for defining the systems that Ansible manages.  
It lists target hosts, organizes them into groups, and specifies connection details like SSH ports and users.  
Inventory files can also include host-specific or group-specific variables to customize task execution.  
They support both static and dynamic setups, making them suitable for a variety of environments.  
By centralizing this information, inventory files enable efficient automation across multiple systems.  

### Examples
**Example 1**
To set only localhost create a yml file like this

```bash
vim local-inventory.yml
```

insert this into the file
```yaml
all:
  hosts:
    localhost:
        ansible_connection: local
```

run this command to ping the local machine through ansible
```bash
ansible -i local-inventory.yml localhost -m ping
```

**Example 2**
create ansible ssh connection to remote linux machine

```bash
vim remote-inventory.yml
```

insert this into the file
```bash
all:
  hosts:
    web01:
      ansible_host: <IP>
      ansible_user: <user on remote machine>
      ansible_ssh_private_key_file: clientkey.pem   
```

This YAML-based inventory file defines a host configuration for Ansible automation. The structure is as follows:

- Group (all): Represents the top-level group containing all hosts.
- Host (web01): Specifies a single host within the group.
  - ansible_host: The IP address or hostname of the target machine.
  - ansible_user: The username used for SSH connection to the remote machine.
  - ansible_ssh_private_key_file: The path to the private key file (clientkey.pem) used for authentication.

This configuration allows Ansible to connect securely to the web01 host and execute tasks.

If there are multiple machines in multiple groups it would look something like this
```yml
all:
  children:
    webservers:
      hosts:
        web01:
          ansible_host: <IP1>
          ansible_user: <user1>
          ansible_ssh_private_key_file: clientkey1.pem
        web02:
          ansible_host: <IP2>
          ansible_user: <user2>
          ansible_ssh_private_key_file: clientkey2.pem
    dbservers:
      hosts:
        db01:
          ansible_host: <IP3>
          ansible_user: <user3>
          ansible_ssh_private_key_file: clientkey3.pem
        db02:
          ansible_host: <IP4>
          ansible_user: <user4>
          ansible_ssh_private_key_file: clientkey4.pem
```

It is somewhat unclear how the /etc/ansible/ansible.cfg file is scaffolded or not scaffolded at all.  
If it is not scaffolded via package manager, create the dir `mkdir /etc/ansible`  
configure file `sudo vim /etc/ansible/ansible.cfg`
Insert 
```yml
host_key_checking=False
```

If there are still errors connecting to remote linux machine through ansible run
```bash
chmod 400 clientkey.pem
```
on the private key

**Example 3**  
Here are just 3 hosts, no groups
```yml
all:
  hosts:
    web01:
      ansible_host: 172.31.31.178
      ansible_user: ec2-user
      ansible_ssh_private_key_file: clientkey.pem
    web02:
      ansible_host: 172.31.31.179
      ansible_user: ec2-user
      ansible_ssh_private_key_file: clientkey.pem
    db01:
      ansible_host: 172.31.31.177
      ansible_user: ec2-user
      ansible_ssh_private_key_file: clientkey.pem

  children:
    webservers:
      hosts:
        web01:
        web02:
    dbservers:
      hosts:
        db01:
    dc-oregon:
      children:
        webservers:
        dbservers:
```

commands to run here
```bash
ansible web01 -m ping -i inventory
```

```bash
ansible web02 -m ping -i inventory
```

```bash
ansible db01 -m ping -i inventory
```

```bash
ansible webservers -m ping -i inventory
```

```bash
ansible dbservers -m ping -i inventory
```

## Ad hoc commands
Ansible scripts are called playbooks, but ad hoc commands can be executed against all machines.  
Not the best practice, but to quickly do something this is fine.

An example could  be to reboot all machines in the atlanta group
```
ansible atlanta -a "/sbin/reboot"
```

Other commands are `ansible.builtin.copy` and `ansible.builtin.file`
Use package managers with `ansible.builtin.pacman` or `ansible.builtin.dnf`

examples
```bash
ansible web01 -m ansible.builtin.yum -a "name=http state=present" -i inventory --become
```
can also use absent as state. --become is use the user as sudo
This is configuration management.

```
ansible webservers -m ansible.builtin.service -a "name=http state=started enabled=yes" -i inventory --become
```

```bash
ansible webservers -m ansible.builtin.copy -a "src=index.html dest=/var/www/html/index.html" -i inventory --become
```

## Playbooks and Modiules
Playbooks are YAML. define hosts and tasks. a play is one set of hosts and tasks. It can also be multiple tasks in a play.

```yaml
---
- name: Webserver setup
  hosts: webservers
  become: yes
  tasks:
    - name: Install httpd
      ansible.builtin.yum:
        name: httpd
        state: present

    - name: Start service
      anisble.builtin.service:
        name: httpd
        state: started
        enabled: yes

- name: DBserver setup
  hosts: dbservers setup
  become: yes
  tasks:
    - name: Install mariadb-server
      ansible.builtin.yum:
        name: mariadb-server
        state: present
```

This can ansible file can be run with `ansible-playbook -i inventory web-db.yaml`

Add debugging with the flag `-v` at the end of the command
Add two `-vv` to get even more verbose output.
Add three `-vvv` to get the most verbose output.

To only check syntax add the flag `--syntax-check`

Use the `-C` command to dry run. 

### Modules
See updated list of modules [here](https://docs.ansible.com/ansible/latest/collections/index_module.html)

examples
