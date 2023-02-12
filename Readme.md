# Bare metal K3s

The aim of this project is to set up the necessary infrastructure for running a Kubernetes cluster on a local machine. This repository contains configuration files and scripts used to deploy virtual machines and provisioning the cluster.

## Inventory:

HP DL380e server
* CPU: Dual socket Intel E5-2430L v2
* Memory: 48 GB RAM
* Storage: 4TB
* OS: Esxi 6.5

## Terraform

Terraform is an infrastructure provisioning software which is used in this project to create virtual machines.
Out of the box it does not integrate with Esxi so a custom provider is needed. Luckily josenk has developed a Terraform provider for Esxi which can be found [here](https://github.com/josenk/terraform-provider-esxi). [OVF Tool](https://developer.vmware.com/web/tool/4.4.0/ovf) is also required for the provider to function.

The operating system for the virtual machines is up to the user. I have gone with Photon OS, an operating system designed by VMWare for Kubernets clusters. The OVA file containing the OS will be placed in the OVA folder which will then be used by Terraform when deploying.

The Photon OVA has one root user with preset password that requires change on first log in. The helper scripts included with this repository will log in to the machines after creation, change the password and copy the ssh key. Additionaly the hostname of the machine will be changed to match the VM name. The repository includes a *.tfvars* template which can be copied and filled in with Esxi server details and new password.

### Terraform commands
``` 
terraform init # initialize the project
terraform plan -var-file=".tfvars" # display changes that will be made
terraform apply # apply the changes; will create vms
```
### Terraform notes:
Changing *numvcpus*, *memsize*, *nic_type* after vm creation will edit the VM, does not require their re-creation.

In some instances OVF tool will fail with a *segfault*. Cause is uncertain but creating fewer machines at the same time seems to solve the issue.

## Ansible

Ansible is straightforward to set up and use. It provides a convenient way of of configuring machines by describing their desired stated and then running through the necessary steps to get to it.

To deploy a simple K3s cluster Rancher provides a [tutorial](https://www.suse.com/c/rancher_blog/deploying-k3s-with-ansible/) accompanied by a functional [playbook](https://github.com/k3s-io/k3s-ansible). After cloning the k3s-ansible repository a custom *inventory* file needs to be provided containing the hostnames/ips of the virtual machines to be configured, the repo provides a template hosts file that can be copied to a new folder and passed to the playbook.

### Ansible commands:
```
 ansible-playbook site.yml -i inventory/my-cluster/hosts.ini -K # deploy the cluster

 ansible-playbook reset.yml -i inventory/my-cluster/hosts.ini -K # reset/uninstall the cluster
 ```

### Ansible notes:

Setting up the playbook and running it it was observed that it gets stuck at one of the final stages *TASK [k3s/node : Enable and check K3s service]*. This is likely due to the master node being unable to initiate a connection with the worker nodes. There are two solutions that resolve this.
* Change the **hosts.ini** file in the inventory to use IP addresses instead of host names. This solution has been proposed [here](https://github.com/k3s-io/k3s-ansible/issues/57)
* Change the firewall policy to allow outside connections, do this on the master node. 
``` 
systemctl stop iptables & systemctl disable iptables # stops the firewall completely; NOT GREAT
iptables --policy INPUT ACCEPT
```

