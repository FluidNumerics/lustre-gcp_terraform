
variable "project_id" {
  type        = string
  description = "Project ID to create resources in."
}

variable "region" {
  type        = string
  description = "Default Google Cloud region"
}

variable "zone" {
  type        = string
  description = "Zone to deploy Lustre file system"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork that will host the Lustre filesystem"
  default = "default"
}

variable "lustre" {
  type = object({
    local_mount = string
    image = string
    service_account = string
    network_tags = list(string)
    name = string
    fs_name = string
    mds_node_count = number
    mds_machine_type = string
    mds_boot_disk_type = string
    mds_boot_disk_size_gb = number
    mdt_disk_type = string
    mdt_disk_size_gb = number
    mdt_per_mds = number
    oss_node_count = number
    oss_nic_type = string
    oss_machine_type = string
    oss_boot_disk_type = string
    oss_boot_disk_size_gb = number
    ost_disk_type = string
    ost_disk_size_gb = number 
    ost_per_oss = number
    hsm_node_count = number
    hsm_machine_type = string
    hsm_gcs_bucket = string
    hsm_gcs_prefix = string
  })
  default = {
    local_mount = "/mnt/lustre"
    image = "projects/rcc-midjourney/global/images/lustre-gcp-2-12-7-gvnic"
    service_account = null
    network_tags = []
    name = "rcc-lustre"
    fs_name = "lustre"
    mds_node_count = 1
    mds_machine_type = "n2-standard-16"
    mds_boot_disk_type = "pd-standard"
    mds_boot_disk_size_gb = 100
    mdt_disk_type = "pd-ssd"
    mdt_disk_size_gb = 1024
    mdt_per_mds = 1
    oss_node_count = 2
    oss_machine_type = "n2-standard-16" 
    oss_nic_type = "GVNIC"
    oss_boot_disk_type = "pd-standard"
    oss_boot_disk_size_gb = 100
    ost_disk_type = "local-ssd"
    ost_disk_size_gb = 1500 
    ost_per_oss = 1
    hsm_node_count = 0
    hsm_machine_type = "n2-standard-16"
    hsm_gcs_bucket = null
    hsm_gcs_prefix = null
  }
}
