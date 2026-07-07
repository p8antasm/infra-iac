# Configure the Proxmox provider with API connection details
provider "proxmox" {
  endpoint        = var.pm_api_url
  api_token       = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure        = true
}


# Create 3 K3s worker nodes by cloning the golden image
resource "proxmox_virtual_environment_vm" "k3s-node" {
  count             = 3
  name              = "k3s-node-${count.index + 1}"
  node_name         = var.proxmox_node
  vm_id             = 9200 + count.index
  clone {
    vm_id           = var.source_vm_id
  }
  agent {
    enabled         = true
  }
  memory {
    dedicated       = 2048
  }
  cpu {
    cores           = 2
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
