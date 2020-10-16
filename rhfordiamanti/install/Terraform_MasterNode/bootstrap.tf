resource "vsphere_virtual_machine" "rhcos_boot" {
  count            = 1
  name             = "ks-k8s-ocp-b-0"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host241.id
  wait_for_guest_net_routable = false
  wait_for_guest_ip_timeout = 1

  num_cpus = lookup(var.env, "num_cpus")
  memory   = lookup(var.env, "memory")
  guest_id = lookup(var.env, "guest_id")

  network_interface {
    network_id     = data.vsphere_network.network_3.id
    use_static_mac = true
    mac_address    = "00:50:56:00:00:00"
  }

  disk {
    label            = "disk0"
    size             = 120
    thin_provisioned = true
  }

  cdrom {
    datastore_id = data.vsphere_datastore.iso_datastore.id
    path         = var.iso_image
  }

}

#resource "vsphere_compute_cluster_vm_group" "cluster_vm_group_k8s" {
#  name                = "ks-k8s"
#  compute_cluster_id  = data.vsphere_compute_cluster.compute_cluster.id
#  virtual_machine_ids = vsphere_virtual_machine.vm_ubuntu.*.id
#}
