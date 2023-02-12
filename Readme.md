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

