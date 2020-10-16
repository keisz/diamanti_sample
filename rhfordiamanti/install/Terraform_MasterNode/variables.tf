variable "vsphere_user" {
  default = "administrator@vc.local"
}

variable "vsphere_password" {
  default = "P@ssw0rd"
}

variable "vsphere_server" {
  default = "vcsa2.vc.local"
}

variable "vsphere" {
  type = map
  default = {
    "datacenter_name"    = "PIC"
    "datastore_name"     = "V9KDS5T (4)"
    "iso_datastore_name" = "V9KDS5T (2)"
    "cluster_name"       = "UCS-vSAN"
    "resource_pool_name" = "k8s"
    "vsphere_host_1"     = "10.42.111.240"
    "vsphere_host_2"     = "10.42.111.241"
    "vsphere_host_3"     = "10.42.111.242"
    "network_name_1"     = "VM Network"
    "network_name_2"     = "local"
    "network_name_3"     = "PIC_Rack3_VLAN450"
    "folder_name"        = "k8s"
  }
}

variable "env" {
  type = map
  default = {
    "vm_count"     = "3"
    "domain"       = "k8s.ks-pic.local"
    "guest_id"     = "rhel7_64Guest"
    "num_cpus"     = 8
    "memory"       = 16384
    "ipv4_netmask" = 16
    "ipv4_gateway" = "172.16.0.1"
    "disk_master"  = 200
    "disk_worker"  = 200
  }
}

//172.16.0.xxx
variable "ipv4_start" {
  default = 100
}


variable "iso_image" {
  default = "/iso/rhcos-4.3.8-x86_64-installer.x86_64.iso"
}




//vm guest_id
//https://vdc-download.vmware.com/vmwb-repository/dcr-public/da47f910-60ac-438b-8b9b-6122f4d14524/16b7274a-bf8b-4b4c-a05e-746f2aa93c8c/doc/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html

