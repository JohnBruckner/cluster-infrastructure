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

## Support infrastructure
A separate machine is useful to have to manage the cluster. I use an Ubuntu 22.04 LTS server VM running on the same hardware as the cluster for this purpose.

### Kubectl

The following steps configure the remote machine to have access to the cluster:
1. SSH into the master node
2. Run the following command 
2. ```cat /etc/rancher/k3s/k3s.yaml```.
3. Copy and paste the output text into a notepad and replace the following line *https://127.0.0.1:6443* with the IP of your master node
4. On your designated management machine:
5. Create the kube directory in your user home directory 
5. ```mkdir ~/.kube```
6. Create a configuration file in the .kube directory using your favourite editor
6. ```vim ~/.kube/config```
7. Paste the contents from your notepad into this file and save it (esc :wq)
8. Install **kubectl**. The official Kubernetes documentation provides several ways listed [here](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
8. Since I use Ubuntu I can install **kubectl** through **snap**
9. ```snap install kubectl --classic```

### Helm
1. [Install Helm 3](https://helm.sh/docs/intro/install/) on the management machine
2. Helm will use the Kubectl config file to liason with the cluster

