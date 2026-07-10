# Configure the Proxmox provider with API connection details
provider "proxmox" {
  endpoint        = var.pm_api_url
  api_token       = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure        = true
}


# Create k3s_master nodes
resource "proxmox_virtual_environment_vm" "k3s_master_node" {
  count             = var.k3s_master_resources.instances
  name              = "k3s-node-${count.index + 1}"
  node_name         = var.proxmox_node
  vm_id             = var.vm_id_base_number + count.index
  reboot            = true
  clone {
    vm_id           = var.source_vm_id
  }
  agent {
    enabled         = true
  }
  memory {
    dedicated       = var.k3s_master_resources.ram_mb
  }
  cpu {
    cores           = var.k3s_master_resources.cpu_cores
  }
  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = var.k3s_master_resources.disk_size
    discard      = "on"
    ssd          = true
  }
  initialization {
    dns {
      servers = ["192.168.0.1"]
    }
    user_account {
      username = "root"
      keys     = [var.ssh_authorized_keys]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

# Create k3s_worker_nodes
resource "proxmox_virtual_environment_vm" "k3s_node" {
  count             = var.k3s_worker_resources.instances
  name              = "k3s-node-${count.index + var.k3s_master_resources.instances + 1}"
  node_name         = var.proxmox_node
  vm_id             = var.vm_id_base_number + var.k3s_master_resources.instances + count.index
  reboot            = true
  clone {
    vm_id           = var.source_vm_id
  }
  agent {
    enabled         = true
  }
  memory {
    dedicated       = var.k3s_worker_resources.ram_mb
  }
  cpu {
    cores           = var.k3s_worker_resources.cpu_cores
  }
  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = var.k3s_worker_resources.disk_size
    discard      = "on"
    ssd          = true
  }
  initialization {
    dns {
      servers = ["192.168.0.1"]
    }
    user_account {
      username = "root"
      keys     = [var.ssh_authorized_keys]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}
