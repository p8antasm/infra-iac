provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_api_token_id
  pm_password     = var.pm_api_token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "k3s-node" {
  count             = 3
  name              = "debian-13-k3s-node-${count.index + 1}"
  vmid              = 9200 + count.index
  target_node       = var.proxmox_node
  clone             = var.source_vm_id
  storage           = var.storage_pool
  cores             = 2
  memory            = 2048
  scsi_controller   = "virtio-scsi-pci"
  network_adapters {
    bridge          = "vmbr0"
    model           = "virtio"
  }
  ipconfig {
    ip              = "dhcp"
  }
  sshkeys           = var.ssh_authorized_keys
  nameserver        = "192.168.0.1"
}
