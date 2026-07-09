variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type = string
}

variable "proxmox_node" {
  type    = string
  default = "rip-pc"
}

variable "source_vm_id" {
  type    = number
  default = 9100 # Golden image ID
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "ssh_authorized_keys" {
  type = string
}

variable "k3s_master_resources" {
  type = object({
    instances     = number
    cpu_cores     = number
    ram_mb        = number
    disk_size     = number
  })
  default = {
    instances     = 1
    cpu_cores     = 2
    ram_mb        = 4
    disk_size     = 18
  }
}

variable "k3s_worker_resources" {
  type = object({
    instances     = number
    cpu_cores     = number
    ram_mb        = number
    disk_size     = number
  })
  default = {
    instances     = 2
    cpu_cores     = 4
    ram_mb        = 8
    disk_size     = 28
  }
}

variable "vm_id_base_number" {
  type = number
  default = 9200
}
