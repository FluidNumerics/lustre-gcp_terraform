variable "create_lustre" {
  type = bool
  description = "Boolean for controlling lustre creation (useful for optional modules)"
  default = true
}

variable "image" {
  type = string
  description = "VM Image for Lustre on Google Cloud"
}

variable "project" {
  type = string
  description = "GCP Project ID"
}

variable "zone" {
  type = string
  description = "GCP Zone to deploy Lustre Cluster"
}

variable "vpc_subnet" {
  type = string
  description = "VPC Subnetwork to host Lustre Cluster"
}

variable "service_account" {
  type = string
  description = "Service account to align with Lustre Cluster GCE instances"
  default = "default"
}

variable "network_tags" {
  type = list(string)
  description = "Network tags"
  default = ["lustre"]
}

variable "cluster_name" {
  type = string
  default = "lustre"
  description = "Name of the Lustre cluster. This name prefixes all compute instances that are created"
}

variable "fs_name" {
  type = string
  default = "lustre"
  description = "Name of the Lustre filesystem. This name determines the server directory path for mounting"
}

variable "mds_node_count" {
  type = number
  default = 1
  description = "Number of MDS node instances to run."
}

variable "mds_machine_type" {
  type = string
  default = "n1-standard-32"
  description = "Machine type to use for MDS node instances, eg. n1-standard-4.."
}

variable "mds_boot_disk_type" {
  type = string
  default = "pd-standard"
  description = "Disk type (pd-ssd or pd-standard) for MDT boot disk."

  validation {
    condition = contains(["pd-standard","pd-ssd","pd-balanced"], var.mds_boot_disk_type)
    error_message = "Allowed values for mdt_disk_type are \"pd-standard\",\"pd-ssd\", or \"pd-balanced\"."
  }
}

variable "mds_boot_disk_size_gb" {
  type = number
  default = 100
  description = "Size of disk for the MDS boot disk (in GB)."

  validation {
    condition = var.mds_boot_disk_size_gb >= 20 && var.mds_boot_disk_size_gb <= 64000
    error_message = "MDS Boot disk size must be greater than or equal to 20GB and less than or equal to 64,000 GB."
  }
}

variable "mdt_disk_type" {
  type = string
  default = "pd-ssd"
  description = "Disk type (pd-ssd, pd-standard, pd-balanced, local-ssd) for MDT disks."

  validation {
    condition = contains(["pd-standard","pd-ssd","pd-balanced","local-ssd"], var.mdt_disk_type)
    error_message = "Allowed values for mdt_disk_type are \"pd-standard\",\"pd-ssd\", \"pd-balanced\", or \"local-ssd\"."
  }
}

variable "mdt_disk_size_gb" {
  type = number
  default = 1024
  description = "Size of disk for the MDT disks (in GB)."

  validation {
    condition = var.mdt_disk_size_gb >= 10 && var.mdt_disk_size_gb <= 3000
    error_message = "MDT disk size must be greater than or equal to 10GB and less than or equal to 3,000 GB."
  }
}

variable "mdt_per_mds" {
  type = number
  default = 1
  description = "Number of MDT disks per MDS instance."

  validation {
    condition = var.mdt_per_mds == 1
    error_message = "MDT per MDS currently restricted to 1 when using PD disks."
  }
}

variable "oss_node_count" {
  type = number
  default = 4
  description = "Number of OSS node instances to run."
}

variable "oss_machine_type" {
  type = string
  default = "n2-standard-16"
  description = "GCP Machine type for the object storage server nodes."
}

variable "oss_boot_disk_type" {
  type = string
  default = "pd-standard"
  description = "Disk type (pd-ssd or pd-standard) for OSS boot disk."

  validation {
    condition = contains(["pd-standard","pd-ssd","pd-balanced"], var.oss_boot_disk_type)
    error_message = "Allowed values for oss_boot_disk_type are \"pd-standard\",\"pd-ssd\", or \"pd-balanced\"."
  }
}

variable "oss_boot_disk_size_gb" {
  type = number
  default = 100
  description = "Size of the OSS boot disk (in GB)"

  validation {
    condition = var.oss_boot_disk_size_gb >= 20 && var.oss_boot_disk_size_gb <= 64000
    error_message = "OSS Boot disk size must be greater than or equal to 20GB and less than or equal to 64,000 GB."
  }
}

variable "ost_disk_type" {
  type = string
  default = "local-ssd"
  description = "Disk type (pd-ssd, pd-standard, pd-balances, or local-ssd) for OST disks."

  validation {
    condition = contains(["pd-standard","pd-ssd","pd-balanced","local-ssd"], var.ost_disk_type)
    error_message = "Allowed values for ost_disk_type are \"pd-standard\",\"pd-ssd\",\"pd-balanced\",or \"local-ssd\"."
  }
}

variable "ost_disk_size_gb" {
  type = number
  default = 1500
  description = "Size of disk for the OST disks (in GB)."

  validation {
    condition = var.ost_disk_size_gb >= 10 && var.ost_disk_size_gb <= 3000
    error_message = "OST disk size must be greater than or equal to 10GB and less than or equal to 3,000 GB."
  }
}

variable "ost_per_oss" {
  type = number
  default = 1
  description = "Number of OST disk per OSS instances"
}

variable "hsm_node_count" {
  type = number
  default = 0
  description = "Number of Lustre HSM Data Movers node instances to run."
}

variable "hsm_machine_type" {
  type = string
  default = "n1-standard-8"
  description = "Machine type to use for Lustre HSM Data Movers node instances, eg. n1-standard-4."
}

variable "hsm_gcs_bucket" {
  type = string
  default = ""
  description = "Google Cloud Storage bucket to archive to."
}

variable "hsm_gcs_prefix" {
  type = string
  default = ""
  description = "Google Cloud Storage bucket path to import data from to Lustre."
}

output "server_ip" {
  value = google_compute_instance.mds[0].name
}
