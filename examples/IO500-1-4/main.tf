############
# PROVIDER #
############

provider "google" {
  project = var.project_id
  region  = var.region
}

##############
# Google API #
##############

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 12.0"

  project_id = var.project_id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
  ]

  enable_apis                 = true
  disable_services_on_destroy = false
}

module "lustre" {
  source = "../../"
  create_lustre = true
  image = var.lustre.image
  project = var.project_id
  zone = var.zone
  vpc_subnet = var.subnetwork
  service_account = var.lustre.service_account 
  network_tags = var.lustre.network_tags
  cluster_name = var.lustre.name
  fs_name = var.lustre.fs_name
  mds_node_count = var.lustre.mds_node_count
  mds_machine_type = var.lustre.mds_machine_type
  mds_boot_disk_type = var.lustre.mds_boot_disk_type
  mds_boot_disk_size_gb = var.lustre.mds_boot_disk_size_gb
  mdt_disk_type = var.lustre.mdt_disk_type
  mdt_disk_size_gb = var.lustre.mdt_disk_size_gb
  mdt_per_mds = var.lustre.mdt_per_mds
  oss_node_count = var.lustre.oss_node_count
  oss_machine_type = var.lustre.oss_machine_type
  oss_nic_type = var.lustre.oss_nic_type
  oss_boot_disk_type = var.lustre.oss_boot_disk_type
  oss_boot_disk_size_gb = var.lustre.oss_boot_disk_size_gb
  ost_disk_type = var.lustre.ost_disk_type
  ost_disk_size_gb = var.lustre.ost_disk_size_gb
  ost_per_oss = var.lustre.ost_per_oss
  hsm_node_count = var.lustre.hsm_node_count
  hsm_machine_type = var.lustre.hsm_machine_type
  hsm_gcs_bucket = var.lustre.hsm_gcs_bucket
  hsm_gcs_prefix = var.lustre.hsm_gcs_prefix
}

