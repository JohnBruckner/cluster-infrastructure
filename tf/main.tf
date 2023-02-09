provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = var.esxi_hostssl
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

resource "esxi_guest" "worker-deploy" {
	count = 2
	guest_name = "tf-k3-worker-${count.index}"
	disk_store = var.esxi_storage
	boot_disk_size = "36"
	ovf_source = "../ova/photon-ova-4.0.ova"
	guest_startup_timeout = "180"
	memsize = "4096"
	numvcpus = "4"
	network_interfaces {
		virtual_network = "VM Network"
		nic_type = "vmxnet3"
	}

	provisioner "local-exec" {
		command = "../scripts/pwdAutomation.sh ${self.ip_address} ${var.vm_old_pwd} ${var.vm_new_pwd} ${self.guest_name}"
		interpreter = ["/bin/bash", "-c"]
		working_dir = path.module
	}

	connection {
		type = "ssh"
		user = "root"
		password = var.vm_new_pwd
		host = self.ip_address
	}
	
	provisioner "remote-exec" {
		inline = ["hostnamectl set-hostname \"${self.guest_name}\"",
				  "shutdown -r +1",
				  "exit 0"]
	}
}


resource "esxi_guest" "control-deploy" {
	count = 1
	guest_name = "tf-k3-control"
	disk_store = var.esxi_storage
	boot_disk_size = "36"
	ovf_source = "../ova/photon-ova-4.0.ova"
	guest_startup_timeout = "180"
	memsize = "4096"
	numvcpus = "4"
	network_interfaces {
		virtual_network = "VM Network"
		nic_type = "vmxnet3"
	}

	provisioner "local-exec" {
		command = "../scripts/pwdAutomation.sh ${self.ip_address} ${var.vm_old_pwd} ${var.vm_new_pwd} ${self.guest_name}"
		interpreter = ["/bin/bash", "-c"]
		working_dir = path.module
	}

	connection {
		type = "ssh"
		user = "root"
		password = var.vm_new_pwd
		host = self.ip_address
	}
	
	provisioner "remote-exec" {
		inline = ["hostnamectl set-hostname \"${self.guest_name}\"",
				  "shutdown -r +1",
				  "exit 0"]
	}
}


