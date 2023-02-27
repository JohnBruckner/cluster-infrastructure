variable "esxi_hostname" {
    default = "esxi"
}

variable "esxi_hostport" {
    default = "22"
}

variable "esxi_hostssl" {
    default = "443"
}

variable "esxi_username" {
    type = string
    # sensitive = true
}

variable "esxi_password" {
    # Unspecified will prompt
    type = string
    sensitive = true
}

variable "esxi_storage" {
    default = "storage"
}

variable "vm_old_pwd" {
    type = string
    sensitive = true
}

variable "vm_new_pwd" {
    type = string
    sensitive = true
}