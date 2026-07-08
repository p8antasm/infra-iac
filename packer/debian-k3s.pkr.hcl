packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

locals {
  unattended_upgrades_conf  = file("${path.root}/assets/unattended-upgrades.conf")
  auto_upgrades_conf        = file("${path.root}/assets/auto-upgrades.conf")
}


# Vars passed from Github Actions
 variable "pm_api_url" { type = string }
 variable "pm_api_token_id" { type = string }
 variable "pm_api_token_secret" { type = string }

variable "proxmox_node" {
  type    = string
  default = "rip-pc"
}

variable "source_vm_id" {
  type    = number
  default = 9000 # Base image ID
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

source "proxmox-clone" "k3s-golden-image" {
  proxmox_url              = var.pm_api_url
  username                 = var.pm_api_token_id
  token                    = var.pm_api_token_secret
  insecure_skip_tls_verify = true

  node                     = var.proxmox_node
  clone_vm_id              = var.source_vm_id
  
  vm_name                  = "debian-13-k3s-golden-image"
  vm_id                    = 9100
  template_description     = "Golden Image Debian 13 optimized for K3s (Cilium, Loki, Tempo) with QEMU Agent. Built via Packer."

  ssh_username             = "root"
  ssh_timeout              = "15m"
    
  numa                     = false
  os                       = "l26"
  cores                    = 2
  memory                   = 2048
  qemu_agent               = true

  cloud_init               = true
  cloud_init_storage_pool  = "local-lvm"
  cloud_init_disk_type     = "scsi"

  scsi_controller          = "virtio-scsi-pci"

  nameserver               = "192.168.0.1"
  network_adapters {
    bridge                 = "vmbr0"
    model                  = "virtio"
  }

  ipconfig {
    ip                     = "dhcp"
  }
}

build {
  name    = "golden-image"
  sources = ["source.proxmox-clone.k3s-golden-image"]

  provisioner "shell" {
    inline = [
      "while sudo fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock >/dev/null 2>&1; do echo 'Waiting for apt lock...'; sleep 5; done",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y cloud-init qemu-guest-agent",
      "sudo systemctl enable qemu-guest-agent"
    ]
  }

  provisioner "shell" {
    script = "scripts/optimize-k3s.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "UNATTENDED_UPDATES_CONF=${local.unattended_upgrades_conf}",
      "AUTO_UPDATES_CONF=${local.auto_upgrades_conf}"
    ]
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove --purge",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get clean",
      "sudo systemctl stop rsyslog || true",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id || true",
      "sudo cloud-init clean --logs",
      "sudo find /var/log -type f -exec truncate -s0 {} +",
      "sudo rm -rf /tmp/* /var/tmp/*",
      "echo \"$UNATTENDED_UPGRADES_CONF\" > sudo tee /etc/apt/apt.conf.d/50-unattended-upgrades.conf > /dev/null",
      "echo \"$AUTO_UPDATES_CONF\" > sudo tee /etc/apt/apt.conf.d/30-auto_upgrades.conf > /dev/null",
    ]
  }
}

