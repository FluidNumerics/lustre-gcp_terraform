project = "<project>"
vpc_subnet = "projects/<project>/regions/<region>/subnetworks/<subnet>"
zone = "<zone>"
image = "projects/<project>/global/images/family/lustre-gcp"


// Edit the settings below to customize your Lustre cluster
//mds_node_count          = 1
//mds_machine_type        = "n1-standard-32"
//mds_boot_disk_type      = "pd-standard"
//mds_boot_disk_size_gb   = 100
//mdt_disk_type           = "pd-ssd"
//mdt_disk_size_gb        = 1024

//oss_node_count          = 4
//oss_machine_type        = "n2-standard-16"
//oss_boot_disk_type      = "pd-standard"
//oss_boot_disk_size_gb   = 100
//ost_disk_type           = "local-ssd"
//ost_disk_size_gb        = 1500

// Lustre HSM Lemur Configuration
//hsm_node_count         = 1
//hsm_machine_type       = "n1-standard-8"
//hsm_gcs_bucket         = "MY_BUCKET"
//hsm_gcs_bucket_import  = "MY_BUCKET_PATH"
