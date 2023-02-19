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
Out of the box it does not integrate with Esxi so a custom provider is needed. Luckily *josenk* has developed a Terraform provider for Esxi which can be found [here](https://github.com/josenk/terraform-provider-esxi). [OVF Tool](https://developer.vmware.com/web/tool/4.4.0/ovf) is also required for the provider to function.

The operating system for the virtual machines is up to the user. I have gone with **Photon OS**, a lightweight operating system designed by VMWare for containerization and hosting Kubernets clusters. The OVA file containing the preffered OS has to be placed in the OVA folder which will then be used by Terraform when deploying.

The **Photon OVA** has one root user with preset password that requires change on first log in. The helper scripts included with this repository will log in to the machines after creation, change the password and copy the ssh key. Additionaly the hostname of the machine will be changed to match the VM name. The repository includes a *.tfvars* template which can be copied and filled in with Esxi server details and new password.

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

Alternatively, Techno Tim has a great [repository](https://github.com/techno-tim/k3s-ansible) where he customized the Ansible K3s project to deploy a Higly Available K3s cluster. The set up is explained in his video [here](https://www.youtube.com/watch?v=CbkEWcUZ7zM).

### Ansible commands:
```
 ansible-playbook site.yml -i inventory/my-cluster/hosts.ini -K # deploy the cluster

 ansible-playbook reset.yml -i inventory/my-cluster/hosts.ini -K # reset/uninstall the cluster
 ```

### Ansible notes:
By default K3s deploys with **Klipper Load Balancer** and **Traefik**, for a basic set up they work great out of the box. However you may want to change them or customize the install. Personally I prefer using **Metal LB** over the default. 

Setting up the playbook and running it it was observed that it gets stuck at one of the final stages *TASK [k3s/node : Enable and check K3s service]*. This is likely due to the master node being unable to initiate a connection with the worker nodes. There are two solutions that resolve this.
* Change the **hosts.ini** file in the inventory to use IP addresses instead of host names. This solution has been proposed [here](https://github.com/k3s-io/k3s-ansible/issues/57)
* Change the firewall policy to allow outside connections, do this on the master node. 
``` 
systemctl stop iptables & systemctl disable iptables # stops the firewall completely; NOT GREAT
iptables --policy INPUT ACCEPT
```

## Support infrastructure
A separate machine is useful to have to manage the cluster. I use an Ubuntu 22.05 LTS server VM running on the same hardware as the cluster for this purpose.

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

### NFS
A storage solution that is independent from the cluster is critical. This way pods do not rely on the nodes storage to save files and thus in the event that a pod goes down and is brought up on another node it will retain access to its data. For example, the monitoring solution that uses Prometheus and Grafana relies on centralised logs which is achieved by storing them in a location separate from the cluster.

The storage world provides many solutions for network storage but for convenience I chose the easiest to implement, NFS shares. A much better alternative would be [Longhorn](https://longhorn.io/) which provides highly available persistent storage for Kubernetes.

Setting up NFS on Ubuntu server is straighforward. This [article](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04) provides a good outline:
1. Install nfs-kernel-server
1. ```sudo apt install nfs-kernel-server```
2. Create a share directory
2. ```mkdir -p /mnt/k3s/nfs_share```
3. Export NFS 
3. ```sudo vim /etc/exports```
3. Add the following line
3. ```/mnt/k3s/nfs_share 192.168.1.0/24(rw,sync,no_subtree_check)```

The clients will also need to be configured in order to access the NFS share. This step can be added as part of the Ansible playbook.
1. Log in to each of virtual machines hosting your kubernetes cluster
2. Install the NFS client 
3. For Photon OS you can use the following command:
4. ```tdnf install nfs-utils```

To use the NFS share in Kubernetes additional configuration will be required for the cluster, however this is out of scope for this project and is covered in covered in the repository for cluster services.




