provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = lookup(var.vsphere, "datacenter_name")
}

data "vsphere_datastore" "datastore" {
  name          = lookup(var.vsphere, "datastore_name")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "iso_datastore" {
  name          = lookup(var.vsphere, "iso_datastore_name")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = lookup(var.vsphere, "cluster_name")
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = lookup(var.vsphere, "resource_pool_name")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host240" {
  name          = lookup(var.vsphere, "vsphere_host_1")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host241" {
  name          = lookup(var.vsphere, "vsphere_host_2")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host242" {
  name          = lookup(var.vsphere, "vsphere_host_3")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network_1" {
  name          = lookup(var.vsphere, "network_name_1")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network_2" {
  name          = lookup(var.vsphere, "network_name_2")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network_3" {
  name          = lookup(var.vsphere, "network_name_3")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}




